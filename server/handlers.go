package server

import (
	"encoding/json"
	"net/http"
	"sort"
	"strings"

	"github.com/dtylman/azbom/sbom"
	"github.com/dustin/go-humanize"
	"github.com/labstack/echo/v4"
)

func (s *Server) initRoutes() {
	api := s.e.Group("/api")

	api.GET("/version", s.handleVersion)

	// Dependencies Page
	api.GET("/references", s.handlerReferences)
	api.GET("/repositories", s.handlerRepositories)
	api.GET("/projects", s.handleProjects)

	// BOM page
	api.GET("/bom", s.handleBOM)
}

// VersionResponse is the response for the version endpoint
type VersionResponse struct {
	Version   string `json:"version"`
	DBCreated string `json:"db_created"`
}

func (s *Server) handleVersion(c echo.Context) error {
	return c.JSON(http.StatusOK, VersionResponse{
		Version:   "0.0.1",
		DBCreated: humanize.Time(s.db.Created),
	})
}

// ReferencesRequest is the request for the references endpoint
type ReferencesRequest struct {
	Project        string `json:"project"`
	DependsOn      bool   `json:"depends_on"`
	DependsBy      bool   `json:"depends_by"`
	OnlyMyProjects bool   `json:"only_my_projects"`
}

// ProjectReference is a reference between two projects
type ProjectReference struct {
	//From is the name of the project that references the other
	From string `json:"from"`
	//To is the name of the project that is referenced
	To string `json:"to"`
}

// ReferencesResponse is the response for the references endpoint
type ReferencesResponse struct {
	References []ProjectReference `json:"references"`
}

// NewReferencesResponse creates a new ReferencesResponse from a ProjectReferences
func NewReferencesResponse(ref *sbom.ProjectReferences) *ReferencesResponse {
	resp := &ReferencesResponse{
		References: make([]ProjectReference, 0),
	}

	for from, to := range ref.References {
		for t := range to {
			resp.AddReference(from, t)
		}
	}

	sort.Slice(resp.References, func(i, j int) bool {
		if resp.References[i].From == resp.References[j].From {
			return strings.ToLower(resp.References[i].To) < strings.ToLower(resp.References[j].To)
		}
		return strings.ToLower(resp.References[i].From) < strings.ToLower(resp.References[j].From)
	})

	return resp
}

// AddReference adds a reference between two projects
func (pr *ReferencesResponse) AddReference(from, to string) {
	if pr.References == nil {
		pr.References = make([]ProjectReference, 0)
	}

	if from == "" || to == "" {
		return
	}

	if strings.EqualFold(from, to) {
		return
	}

	for _, ref := range pr.References {
		if strings.EqualFold(ref.From, from) && strings.EqualFold(ref.To, to) {
			return
		}
	}

	pr.References = append(pr.References, ProjectReference{From: from, To: to})
}

func (s *Server) handlerReferences(c echo.Context) error {
	req := ReferencesRequest{
		OnlyMyProjects: true,
	}
	reqStr := c.QueryParam("req")
	if reqStr != "" {
		err := json.Unmarshal([]byte(reqStr), &req)
		if err != nil {
			return err
		}
	}
	refs := s.db.NewReferences(req.OnlyMyProjects)
	if req.Project == "" {
		return c.JSON(http.StatusOK, NewReferencesResponse(refs))
	}
	out := sbom.NewProjectReferences()
	if req.DependsOn {
		refs.DependsOn(req.Project, out)
	}
	if req.DependsBy {
		refs.WhoDepends(req.Project, out)
	}
	return c.JSON(http.StatusOK, NewReferencesResponse(out))
}

func (s *Server) handlerRepositories(c echo.Context) error {
	return c.JSON(http.StatusOK, s.db.Repositories())
}

type ProjectSummary struct {
	Name string `json:"name"`
	// RepoName is the name of the repository
	RepoName string `json:"repo_name"`
	// BasePath is the base path of the project
	BasePath string `json:"base_path"`
	// TargetFramework is the target framework of the project
	TargetFramework string `json:"target_framework"`
	// ProjectFile is the path to the project file
	ProjectFile string `json:"project_file"`
	// MainFile is the path to the main file
	MainFile string `json:"main_file"`
}

func (s *Server) handleProjects(c echo.Context) error {
	internalOnly := c.QueryParam("internal")
	repo := c.QueryParam("repo")
	io := strings.EqualFold(internalOnly, "true")

	var projects []ProjectSummary

	for _, p := range s.db.Projects {
		if !p.IsProject() {
			continue
		}
		if io || !s.db.HasProject(p.Name) {
			continue
		}
		if repo != "" && !strings.EqualFold(p.RepoName, repo) {
			continue
		}
		if p.Name == "" {
			continue
		}
		projects = append(projects, ProjectSummary{
			Name:            p.Name,
			RepoName:        p.RepoName,
			BasePath:        p.BasePath,
			TargetFramework: p.TargetFramework,
			ProjectFile:     p.ProjectFile,
			MainFile:        p.MainFile,
		})

	}

	sort.Slice(projects, func(i, j int) bool {
		if projects[i].RepoName == projects[j].RepoName {
			return strings.ToLower(projects[i].Name) < strings.ToLower(projects[j].Name)
		}
		return strings.ToLower(projects[i].RepoName) < strings.ToLower(projects[j].RepoName)
	})
	return c.JSON(http.StatusOK, projects)

}

func (s *Server) handleBOM(c echo.Context) error {
	var allProjects []sbom.Project
	for _, p := range s.db.Projects {
		allProjects = append(allProjects, *p)
	}
	sort.Slice(allProjects, func(i, j int) bool {
		if allProjects[i].RepoName == allProjects[j].RepoName {
			return strings.ToLower(allProjects[i].Name) < strings.ToLower(allProjects[j].Name)
		}
		return strings.ToLower(allProjects[i].RepoName) < strings.ToLower(allProjects[j].RepoName)
	})
	return c.JSON(http.StatusOK, allProjects)
}
