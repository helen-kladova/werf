// +build integration

package docs_test

import (
	"os"
	"path/filepath"
	"runtime"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/ginkgo/extensions/table"
	. "github.com/onsi/gomega"

	"github.com/flant/werf/integration/utils"
)

type entry struct {
	fixturesDir   string
	extraArgsFunc func() []string
}

var _ = BeforeEach(func() {
	if runtime.GOOS == "windows" {
		Skip("skip on windows")
	}

	Ω(os.Setenv("WERF_HELM_HOME", "~/.helm")).Should(Succeed())
	Ω(os.Setenv("WERF_LOG_TERMINAL_WIDTH", "100")).Should(Succeed())
})

var itBody = func(entry entry) {
	resolvedExpectationPath, err := filepath.EvalSymlinks(fixturePath(entry.fixturesDir, "expectation"))
	Ω(err).ShouldNot(HaveOccurred())

	utils.CopyIn(resolvedExpectationPath, filepath.Join(testDirPath, "expectation"))

	utils.RunSucceedCommand(
		testDirPath,
		"git",
		"init",
	)

	utils.RunSucceedCommand(
		testDirPath,
		"git",
		"add", ".",
	)

	utils.RunSucceedCommand(
		testDirPath,
		"git",
		"add", "-A",
	)

	utils.RunSucceedCommand(
		testDirPath,
		"git",
		"commit", "-m", "+",
	)

	Ω(os.RemoveAll("output_dir")).Should(Succeed())

	werfArgs := []string{"docs", "--dir", filepath.Join(testDirPath, "expectation")}

	if entry.extraArgsFunc != nil {
		werfArgs = append(werfArgs, entry.extraArgsFunc()...)
	}

	utils.RunSucceedCommand(
		testDirPath,
		werfBinPath,
		werfArgs...,
	)

	utils.RunSucceedCommand(
		testDirPath,
		"git",
		"add", "-A",
	)

	utils.RunSucceedCommand(
		testDirPath,
		"git",
		"diff-index", "--exit-code", "HEAD", "--",
	)
}

var _ = DescribeTable("docs", itBody,
	Entry("docs", entry{
		fixturesDir: "docs",
	}),
	Entry("readme", entry{
		fixturesDir: "readme",
		extraArgsFunc: func() []string {
			readmePath, err := filepath.Abs(fixturePath("readme", "README.md"))
			Ω(err).ShouldNot(HaveOccurred())

			return []string{"--split-readme", "--readme", readmePath}
		},
	}))
