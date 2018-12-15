# Author: Sankarsan Kampa (a.k.a. k3rn31p4nic)
# Modified by: etcher
# License: MIT

$STATUS=$args[0]
$WEBHOOK_URL=$args[1]
$ARTIFACT=$args[2]

if (!$WEBHOOK_URL) {
  Write-Output "DISCORD: [Webhook]: No webhook defined, skipping"
  Exit
}

if (!$WEBHOOK_URL) {
  Write-Output "DISCORD: [Webhook]: No artifact defined, skipping"
  Exit
}

Write-Output "DISCORD: [Webhook]: Sending webhook to Discord..."

Switch ($STATUS) {
  "success" {
    $STATUS_MESSAGE="Passed"
    Break
  }
  "failure" {    
    $STATUS_MESSAGE="Failed"
    Break
  }
  default {
    Write-Output "DISCORD: [Webhook]: unknown build status: $STATUS"
    Exit
  }
}
$AVATAR="https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Appveyor_logo.svg/256px-Appveyor_logo.svg.png"

if (!$env:APPVEYOR_REPO_COMMIT) {
  $env:APPVEYOR_REPO_COMMIT="$(git log -1 --pretty="%H")"
}

$AUTHOR_NAME="$(git log -1 "$env:APPVEYOR_REPO_COMMIT" --pretty="%aN")"
$COMMITTER_NAME="$(git log -1 "$env:APPVEYOR_REPO_COMMIT" --pretty="%cN")"
$COMMIT_SUBJECT="$(git log -1 "$env:APPVEYOR_REPO_COMMIT" --pretty="%s")"
$COMMIT_MESSAGE="$(git log -1 "$env:APPVEYOR_REPO_COMMIT" --pretty="%b")"

if ($AUTHOR_NAME -eq $COMMITTER_NAME) {
  $CREDITS="$AUTHOR_NAME authored & committed"
}
else {
  $CREDITS="$AUTHOR_NAME authored & $COMMITTER_NAME committed"
}

if ($env:APPVEYOR_REPO_BRANCH -eq "master") {
  $REL_LABEL="New stable release"  
  $EMBED_COLOR=3066993
}
else {
  $REL_LABEL="New experimental release ($env:APPVEYOR_REPO_BRANCH)"
  $EMBED_COLOR=15158332
}

if ($env:APPVEYOR_PULL_REQUEST_NUMBER) {
  $COMMIT_SUBJECT="PR #$env:APPVEYOR_PULL_REQUEST_NUMBER - $env:APPVEYOR_PULL_REQUEST_TITLE"
  $URL="https://github.com/$env:APPVEYOR_REPO_NAME/pull/$env:APPVEYOR_PULL_REQUEST_NUMBER"
}
else {
  $URL=""
}

$BUILD_VERSION = [uri]::EscapeDataString($env:APPVEYOR_BUILD_VERSION)
$TIMESTAMP="$(Get-Date -format s)Z"
$WEBHOOK_DATA="{
  ""username"": """",
  ""avatar_url"": ""$AVATAR"",
  ""embeds"": [ {
    ""color"": $EMBED_COLOR,
    ""author"": {
      ""name"": ""$REL_LABEL (Build #$env:APPVEYOR_BUILD_NUMBER)"",
      ""url"": ""https://ci.appveyor.com/project/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/build/$BUILD_VERSION"",
      ""icon_url"": ""$AVATAR""
    },
    ""title"": ""$COMMIT_SUBJECT"",
    ""url"": ""$URL"",
    ""description"": ""$COMMIT_MESSAGE $CREDITS"",
    ""fields"": [
      {
        ""name"": ""Direct download"",
        ""value"": ""[$ARTIFACT](https://ci.appveyor.com/api/projects/etcher/$env:APPVEYOR_PROJECT_NAME/artifacts/$ARTIFACT?branch=$env:APPVEYOR_REPO_BRANCH)"",
        ""inline"": true
      },
      {
        ""name"": ""Commit"",
        ""value"": ""[``$($env:APPVEYOR_REPO_COMMIT.substring(0, 7))``](https://github.com/$env:APPVEYOR_REPO_NAME/commit/$env:APPVEYOR_REPO_COMMIT)"",
        ""inline"": true
      },
      {
        ""name"": ""Branch/Tag"",
        ""value"": ""[``$env:APPVEYOR_REPO_BRANCH``](https://github.com/$env:APPVEYOR_REPO_NAME/tree/$env:APPVEYOR_REPO_BRANCH)"",
        ""inline"": true
      }
    ],
    ""timestamp"": ""$TIMESTAMP""
  } ]
}"

Invoke-RestMethod -Uri "$WEBHOOK_URL" -Method "POST" -UserAgent "AppVeyor-Webhook" `
  -ContentType "application/json" -Header @{"X-Author"="etcher#4165"} `
  -Body $WEBHOOK_DATA

Write-Output "DISCORD: [Webhook]: Successfully sent the webhook."
