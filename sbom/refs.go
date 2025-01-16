package sbom

// ProjectReferences is a struct that holds the references between projects
type ProjectReferences struct {
	//References holds a list of References between projects (from->to many)
	References map[string]map[string]bool
}

// NewProjectReferences creates a new ProjectReferences
func NewProjectReferences() *ProjectReferences {
	return &ProjectReferences{
		References: make(map[string]map[string]bool),
	}
}

// AddReference adds a reference between two projects
func (pr *ProjectReferences) AddReference(from string, to string) {
	if _, ok := pr.References[from]; !ok {
		pr.References[from] = make(map[string]bool)
	}
	pr.References[from][to] = true
}

// WhoDepends returns a list of projects that depend on the project
func (pr *ProjectReferences) WhoDepends(name string, out *ProjectReferences) {
	for from, to := range pr.References {
		if _, ok := to[name]; ok {
			out.AddReference(from, name)
			pr.WhoDepends(from, out)
		}
	}
}

// DependsOn returns a list of projects that the project depends on
func (pr *ProjectReferences) DependsOn(fromName string, out *ProjectReferences) {
	to, ok := pr.References[fromName]
	if !ok {
		return
	}
	for name := range to {
		out.AddReference(fromName, name)
		pr.DependsOn(name, out)
	}
}

// Contains returns true if the project is referenced by any other project
func (pr *ProjectReferences) Contains(name string) bool {
	for from := range pr.References {
		if from == name {
			return true
		}
		for to := range pr.References[from] {
			if to == name {
				return true
			}
		}
	}
	return false
}
