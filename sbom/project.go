package sbom

// Project holds information about a single project
type Project struct {
	// Name is the name of the project
	Name string `json:"name"`
	// RepoName is the name of the repository
	RepoName string `json:"repo_name"`
	// MainBranch is the name of the main branch
	MainBranch string `json:"main_branch"`
	// BasePath is the base path of the project
	BasePath string `json:"base_path"`
	// TargetFramework is the target framework of the project
	TargetFramework string `json:"target_framework"`
	// ProjectFile is the path to the project file
	ProjectFile string `json:"project_file"`
	// DockerFiles is a list of paths to Dockerfile(s)
	DockerFiles []string `json:"docker_files"`
	// MainFile is the path to the main file
	MainFile string `json:"main_file"`
	// References holds project references
	References map[string]string `json:"references"`
}

// NewProject creates a new project
func NewProject(repoName, basePath string) *Project {
	return &Project{
		RepoName:    repoName,
		BasePath:    basePath,
		DockerFiles: make([]string, 0),
		References:  make(map[string]string),
	}
}

// Key returns a unique key for the project
func (p *Project) Key() string {
	return p.RepoName + ":" + p.BasePath
}

// IsProject returns true if the project is a valid project
func (p *Project) IsProject() bool {
	return (p.Name != "" || len(p.DockerFiles) > 0 || p.MainFile != "")
}
