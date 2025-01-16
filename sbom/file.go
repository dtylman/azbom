package sbom

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"
	"time"
)

// sbomFile is the name of the sbom file
const sbomFile = "sbom.json"

// File represents the sbom file
type File struct {
	// Created is the time the file was created
	Created time.Time `json:"created"`
	//Projects is a map of projects by key (repoName + basePath)
	Projects map[string]*Project `json:"projects"`
}

// NewFile creates a new sbom file
func NewFile() *File {
	return &File{
		Created:  time.Now(),
		Projects: make(map[string]*Project),
	}
}

// RemoveProject removes the project from the sbom file
func (f *File) RemoveProject(p *Project) {
	delete(f.Projects, p.Key())
}

// GetProject returns the project by key, if not found creates a new one
func (f *File) GetProject(repoName string, basePath string) *Project {
	key := NewProject(repoName, basePath).Key()
	p, ok := f.Projects[key]
	if !ok {
		p = NewProject(repoName, basePath)
		f.Projects[key] = p
	}
	return p
}

// HasProject returns true if the project a specific name exists
func (f *File) HasProject(name string) bool {
	for _, p := range f.Projects {
		if p.Name == name {
			return true
		}
	}
	return false
}

// NewReferences creates a new ProjectReferences from the sbom file
func (f *File) NewReferences(internalOnly bool) *ProjectReferences {
	pr := NewProjectReferences()
	for _, p := range f.Projects {
		for to := range p.References {
			if !internalOnly || f.HasProject(to) {
				pr.AddReference(p.Name, to)
			}
		}
	}
	return pr
}

// Load reads the sbom file from disk
func (f *File) Load() error {
	log.Printf("Loading sbom file from %v", sbomFile)
	data, err := os.ReadFile(sbomFile)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, f)
}

// Save writes the sbom file to disk
func (f *File) Save() error {
	log.Printf("Saving sbom file to %v", sbomFile)
	data, err := json.Marshal(f)
	if err != nil {
		return err
	}
	return os.WriteFile(sbomFile, data, 0644)
}

// keys returns the keys of a map
func keys(m map[string]bool) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}

	sort.Slice(keys, func(i, j int) bool {
		return strings.ToLower(keys[i]) < strings.ToLower(keys[j])
	})

	return keys
}

// Frameworks returns a list of unique frameworks in the sbom file
func (f *File) Frameworks() []string {
	frameworks := make(map[string]bool)
	for _, p := range f.Projects {
		if p.TargetFramework != "" {
			frameworks[p.TargetFramework] = true
		}
	}
	return keys(frameworks)
}

// Repositories returns a list of unique repositories in the sbom file
func (f *File) Repositories() []string {
	repos := make(map[string]bool)
	for _, p := range f.Projects {
		repos[p.RepoName] = true
	}
	return keys(repos)
}

// GetProjects returns a list of projects in the sbom file
func (f *File) GetProjects(internalOnly bool, repo string) []string {
	projs := make(map[string]bool)
	for _, p := range f.Projects {
		if p.Name == "" {
			continue
		}
		if repo != "" && p.RepoName != repo {
			continue
		}
		if !internalOnly || f.HasProject(p.Name) {
			projs[p.Name] = true
		}
	}
	return keys(projs)
}

// ToMermaid returns a mermaid diagram of the sbom file using the provided project references
func (f *File) ToMermaid(pr *ProjectReferences) string {
	var diagram strings.Builder

	diagram.WriteString("graph LR\n")

	colors := []string{
		"#90ee90", // green
		"#ffffe0", // yellow
		"#ffcccb", // red
		"#d3d3d3", // light gray
		"#f0f8ff", // light blue
		"#f0e68c", // khaki
		"#dda0dd", // plum
		"#ffebcd", // blanched almond
		"#f5f5dc", // beige
		"#f5deb3", // wheat
		"#f0ffff", // azure
		"#f0fff0", // honeydew
		"#f0f8ff", // alice blue
		"#f5f5f5", // white smoke
	}
	frameWorks := f.Frameworks()
	for i, fw := range frameWorks {
		color := colors[i%len(colors)]
		diagram.WriteString(fmt.Sprintf("\tclassDef %v fill:%v\n", fw, color))
	}

	for _, p := range f.Projects {
		if !pr.Contains(p.Name) {
			continue
		}

		class := ""
		if p.TargetFramework != "" {
			class = fmt.Sprintf(":::%v", p.TargetFramework)
		}

		if p.MainFile == "" {
			diagram.WriteString(fmt.Sprintf("\t%v%v\n", p.Name, class))
		} else {
			diagram.WriteString(fmt.Sprintf("\t%v([%v])%v\n", p.Name, p.Name, class))
		}
	}

	for from, to := range pr.References {
		for p := range to {
			diagram.WriteString(fmt.Sprintf("\t%v --> %v\n", from, p))
		}
	}

	return diagram.String()
}

// // sort by repo name
// sort.Slice(projects, func(i, j int) bool {
// 	if projects[i].RepoName == projects[j].RepoName {
// 		return projects[i].Name < projects[j].Name
// 	}
// 	return projects[i].RepoName < projects[j].RepoName
// })
