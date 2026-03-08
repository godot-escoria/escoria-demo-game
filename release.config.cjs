module.exports = {
  branches: [
    { name: "main" },                 // future stable releases
    { name: "beta", prerelease: "beta" }  // current prerelease channel
  ],

  tagFormat: "v${version}",

  plugins: [
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "conventionalcommits"
      }
    ],

    [
      "@semantic-release/release-notes-generator",
      {
        preset: "conventionalcommits"
      }
    ],

    [
      "@semantic-release/changelog",
      {
        changelogFile: "CHANGELOG.md"
      }
    ],

    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md"],
        message: "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ],

    [
      "@semantic-release/github",
      {
        successComment: false,
        failComment: false
      }
    ]
  ]
};
