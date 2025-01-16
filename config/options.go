package config

import "github.com/caarlos0/env/v11"

// Options struct to hold the configuration options
var Options struct {
	//OrganizationURL is the URL of the organization
	OrganizationURL string `env:"ORGANIZATION_URL"`
	//Pat is the Personal Access Token
	Pat string `env:"PAT"`
	//ListenPort is the http port to listen
	ListenPort string `env:"LISTEN_PORT" envDefault:":8080"`
	//MaxAge is the maximum age of the database in hours
	MaxAge int `env:"MAX_AGE" envDefault:"24"`
	//FrontFolder is the folder of the front end
	FrontFolder string `env:"FRONT_FOLDER" envDefault:"./frontend"`
}

func init() {
	err := env.Parse(&Options)
	if err != nil {
		panic(err)
	}
}
