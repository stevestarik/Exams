def call(Map config = [:]) {
    echo "Initializing environment and extracting SCM metadata..."

    def scmVars = checkout scm

    def commitHash = scmVars.GIT_COMMIT ?: sh(
        script: "git rev-parse HEAD",
        returnStdout: true
    ).trim()

    def shortCommit = commitHash ? commitHash.take(7) : sh(
        script: "git rev-parse --short HEAD",
        returnStdout: true
    ).trim()

    def branchName = scmVars.GIT_BRANCH ?: sh(
        script: "git rev-parse --abbrev-ref HEAD",
        returnStdout: true
    ).trim()

    def committerName = sh(
        script: "git log -1 --pretty=format:'%an'",
        returnStdout: true
    ).trim()

    def committerEmail = sh(
        script: "git log -1 --pretty=format:'%ae'",
        returnStdout: true
    ).trim()

    def commitMessage = sh(
        script: "git log -1 --pretty=format:'%s'",
        returnStdout: true
    ).trim()

    env.SCM_COMMITTER_NAME  = committerName
    env.SCM_COMMITTER_EMAIL = committerEmail
    env.SCM_COMMIT_MSG      = commitMessage
    env.SCM_COMMIT_HASH     = commitHash
    env.SCM_SHORT_COMMIT    = shortCommit
    env.SCM_BRANCH          = branchName

    def appName = config.appName ?: "my-service"
    env.ARTIFACT_VERSION = "${env.BUILD_NUMBER}-${shortCommit}"
    env.ARTIFACT_NAME    = "${appName}-${env.ARTIFACT_VERSION}.tar.gz"

    echo "Environment Prepared: Branch=${env.SCM_BRANCH}, Commit=${env.SCM_SHORT_COMMIT}, Committer=${env.SCM_COMMITTER_NAME}"

    return [
        committerName : committerName,
        committerEmail: committerEmail,
        commitHash    : commitHash,
        shortCommit   : shortCommit,
        branch        : branchName,
        artifactName  : env.ARTIFACT_NAME
    ]
}