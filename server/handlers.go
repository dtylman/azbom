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

func (s *Server) handleProjects(c echo.Context) error {
	internalOnly := c.QueryParam("internal")
	repo := c.QueryParam("repo")
	if internalOnly == "false" {
		return c.JSON(http.StatusOK, s.db.GetProjects(false, repo))
	}
	return c.JSON(http.StatusOK, s.db.GetProjects(true, repo))
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
