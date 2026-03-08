module.exports = {
  git: {
    requireBranch: "main",
    requireCleanWorkingDir: true,
    commit: true,
    commitMessage: "chore(release): v${version} [skip ci]",
    tag: true,
    tagName: "v${version}",
    push: true
  },

  npm: {
    publish: false,
    skipChecks: true
  },

  github: {
    release: true,
    releaseName: "v${version}"
  },

  plugins: {
    "@release-it/conventional-changelog": {
      infile: "CHANGELOG.md",
      preset: {
        name: "conventionalcommits",
        types: [
          { type: "feat", section: "Features" },
          { type: "fix", section: "Bug Fixes" },
          { type: "perf", section: "Performance" },
          { type: "refactor", section: "Refactoring" },
          { type: "docs", section: "Documentation" },
          { type: "test", section: "Tests" },
          { type: "build", section: "Build System" },
          { type: "ci", section: "CI" },
          { type: "chore", hidden: true }
        ]
      },
      context: {
        host: "https://github.com",
        owner: "godot-escoria",
        repository: "escoria-demo-game",
        linkCompare: true
      }    
    }
  }
};
