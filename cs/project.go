package cs

// PropertyGroup represents a property group of a cs project
type PropertyGroup struct {
	TargetFramework string `xml:"TargetFramework"`
}

// Project represents a CS project
type Project struct {
	PropertyGroup PropertyGroup `xml:"PropertyGroup"`
	ItemGroup     []struct {
		PackageReference []struct {
			Include string `xml:"Include,attr"`
			Version string `xml:"Version,attr"`
		} `xml:"PackageReference"`
		ProjectReference []struct {
			Include string `xml:"Include,attr"`
		} `xml:"ProjectReference"`
	} `xml:"ItemGroup"`
}
