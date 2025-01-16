package sbom

import (
	"context"
	"encoding/xml"
	"errors"
	"io"
	"log"
	"path/filepath"

	"strings"

	"github.com/dtylman/azbom/cs"
	"github.com/microsoft/azure-devops-go-api/azuredevops/v7"
	"github.com/microsoft/azure-devops-go-api/azuredevops/v7/git"
)

// Analyzer is responsible for analyze all projects in a given Azure project and generate the SBOM database.
type Analyzer struct {
	orgURL string
	pat    string
	gc     git.Client
	db     *File
}

// NewAnalyzer creates a new Analyzer
func NewAnalyzer(orgURL, pat string) *Analyzer {
	return &Analyzer{
		orgURL: orgURL,
		pat:    pat,
	}
}

// Analyze reads all projects from Azure DevOps and generates the SBOM database
func (a *Analyzer) Analyze(ctx context.Context) error {
	a.db = NewFile()
	conn := azuredevops.NewPatConnection(a.orgURL, a.pat)
	var err error
	log.Printf("Connecting to Azure DevOps at %v", a.orgURL)
	a.gc, err = git.NewClient(ctx, conn)
	if err != nil {
		return err
	}

	repos, err := a.gc.GetRepositories(ctx, git.GetRepositoriesArgs{})
	if err != nil {
		return err
	}

	if repos == nil || len(*repos) == 0 {
		return errors.New("no repositories found")
	}

	for _, repo := range *repos {
		err := a.processRepo(ctx, repo)
		if err != nil {
			log.Printf("Error processing repo %s: %v", *repo.Name, err)
		}
	}

	return nil
}

// processRepo processes a repository
func (a *Analyzer) processRepo(ctx context.Context, repo git.GitRepository) error {
	repoName := *repo.Name
	repoID := repo.Id.String()
	branches, err := a.gc.GetBranches(ctx, git.GetBranchesArgs{RepositoryId: &repoID})
	if err != nil {
		return err
	}
	log.Printf("Repo %v: found %v branches", repoName, len(*branches))
	for _, branch := range *branches {
		ok, err := a.processBranch(ctx, repoName, repoID, branch)
		if err != nil {
			log.Printf("Error processing branch %s: %v", *branch.Name, err)
		} else if ok {
			// found the main branch, no need to continue
			break
		}
	}
	return nil
}

// processBranch processes a branch
func (a *Analyzer) processBranch(ctx context.Context, repoName, repoID string, branch git.GitBranchStats) (bool, error) {
	if !*branch.IsBaseVersion {
		return false, nil
	}

	trueValue := true
	log.Printf("Branch: %v commit: %v\n", *branch.Name, *branch.Commit.CommitId)
	commit, err := a.gc.GetCommit(ctx, git.GetCommitArgs{RepositoryId: &repoID, CommitId: branch.Commit.CommitId})
	if err != nil {
		return true, err
	}
	tree, err := a.gc.GetTree(ctx, git.GetTreeArgs{RepositoryId: &repoID, Sha1: commit.TreeId, Recursive: &trueValue})
	if err != nil {
		return true, err
	}

	var pi *Project = nil
	for _, item := range *tree.TreeEntries {
		path := *item.RelativePath
		if pi != nil {
			if !pi.IsProject() {
				a.db.RemoveProject(pi)
			}
		}
		basePath := filepath.Dir(path)
		pi = a.db.GetProject(repoName, basePath)
		pi.MainBranch = *branch.Name
		if strings.HasSuffix(path, "Dockerfile") {
			pi.DockerFiles = append(pi.DockerFiles, path)
		} else if strings.HasSuffix(path, ".csproj") {
			err := a.processProject(ctx, pi, repoID, item)
			if err != nil {
				return true, err
			}

		} else if strings.HasSuffix(path, "Program.cs") {
			pi.MainFile = path
		}
	}
	if !pi.IsProject() {
		a.db.RemoveProject(pi)
	}
	return true, nil
}

// processProject processes a project
func (a *Analyzer) processProject(ctx context.Context, pi *Project, repoID string, item git.GitTreeEntryRef) error {
	log.Printf("Reading csproj file: %v", *item.RelativePath)
	reader, err := a.gc.GetBlobContent(ctx, git.GetBlobContentArgs{RepositoryId: &repoID, Sha1: item.ObjectId})
	if err != nil {
		return err
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return err
	}

	var project cs.Project
	err = xml.Unmarshal(data, &project)
	if err != nil {
		return err
	}

	pi.TargetFramework = project.PropertyGroup.TargetFramework
	pi.ProjectFile = *item.RelativePath
	pi.Name = strings.TrimSuffix(filepath.Base(pi.ProjectFile), filepath.Ext(pi.ProjectFile))
	for _, itemGroup := range project.ItemGroup {
		for _, packageReference := range itemGroup.PackageReference {
			pi.References[packageReference.Include] = packageReference.Version
		}
		for _, projectReference := range itemGroup.ProjectReference {
			projectName := strings.ReplaceAll(projectReference.Include, "\\", "/")
			projectName = filepath.Base(projectName)
			projectName = strings.TrimSuffix(projectName, filepath.Ext(projectName))
			pi.References[projectName] = "Project"
		}

	}

	return nil
}

// GetDB returns the SBOM database
func (a *Analyzer) GetDB() *File {
	return a.db
}
