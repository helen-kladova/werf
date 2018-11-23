package deploy

import (
	"fmt"
	"os"
)

type RenderOptions struct {
	ProjectDir   string
	Values       []string
	SecretValues []string
	Set          []string
}

func RunRender(opts RenderOptions) error {
	if debug() {
		fmt.Printf("Render options: %#v\n", opts)
	}

	s, err := getOptionalSecret(opts.ProjectDir, opts.SecretValues)
	if err != nil {
		return fmt.Errorf("cannot get project secret: %s", err)
	}

	serviceValues, err := GetServiceValues("PROJECT_NAME", "REPO", "NAMESPACE", "DOCKER_TAG", nil, nil, ServiceValuesOptions{
		Fake:            true,
		WithoutRegistry: true,
	})

	dappChart, err := getDappChart(opts.ProjectDir, s, opts.Values, opts.SecretValues, opts.Set, serviceValues)
	if err != nil {
		return err
	}
	if !debug() {
		// Do not remove tmp chart in debug
		defer os.RemoveAll(dappChart.ChartDir)
	}

	data, err := dappChart.Render()
	if err != nil {
		return err
	}

	fmt.Printf("%s", data)

	return nil
}