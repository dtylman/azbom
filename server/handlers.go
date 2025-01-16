package server

import (
	"net/http"
	"sort"
	"strings"

	"github.com/dtylman/azbom/sbom"
	"github.com/dustin/go-humanize"
	"github.com/labstack/echo/v4"
)

func (s *Server) initRoutes() {
	api := s.e.Group("/api")

	api.GET("/version", s.version)

	// Dependencies Page
	api.GET("/references", s.references)
	api.GET("/repositories", s.repositories)
	api.GET("/projects", s.projects)

	// BOM page
	api.GET("/bom", s.bomTable)
}

type VersionResponse struct {
	Version   string `json:"version"`
	DBCreated string `json:"db_created"`
}

func (s *Server) version(c echo.Context) error {
	return c.JSON(http.StatusOK, VersionResponse{
		Version:   "0.0.1",
		DBCreated: humanize.Time(s.db.Created),
	})
}

// MermaidResponse is the response for the mermaid diagram
type MermaidResponse struct {
	// Diagram is the mermaid diagram
	Diagram string `json:"diagram"`
}

func str2bool(s string) bool {
	return strings.ToLower(s) != "false"
}

// /api/references?project=&dependsOn=true&dependsBy=true&onlyMyProjects=true 200
func (s *Server) references(c echo.Context) error {
	project := c.QueryParam("project")
	dependsOn := str2bool(c.QueryParam("dependsOn"))
	dependsBy := str2bool(c.QueryParam("dependsBy"))
	onlyMyProjects := str2bool(c.QueryParam("onlyMyProjects"))

	var response MermaidResponse
	refs := s.db.NewReferences(onlyMyProjects)
	if project == "" {
		response.Diagram = s.db.ToMermaid(refs)
		return c.JSON(http.StatusOK, response)
	}
	out := sbom.NewProjectReferences()
	if dependsOn {
		refs.DependsOn(project, out)
	}

	if dependsBy {
		refs.WhoDepends(project, out)
	}

	response.Diagram = s.db.ToMermaid(out)

	return c.JSON(http.StatusOK, response)
}

func (s *Server) repositories(c echo.Context) error {
	return c.JSON(http.StatusOK, s.db.Repositories())
}

func (s *Server) projects(c echo.Context) error {
	internalOnly := c.QueryParam("internal")
	repo := c.QueryParam("repo")
	if internalOnly == "false" {
		return c.JSON(http.StatusOK, s.db.GetProjects(false, repo))
	}
	return c.JSON(http.StatusOK, s.db.GetProjects(true, repo))
}

func (s *Server) bomTable(c echo.Context) error {
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
