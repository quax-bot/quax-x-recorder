# quax-x-recorder

Runs [QuaX](https://github.com/Teskann/QuaX)'s `tool/record/capture.dart` on its `master` and uploads the diff as a `capture-patch` artifact.

```bash
gh workflow run record.yml -R quax-bot/quax-x-recorder -f mode=ONLY -f value=2082854732020760880
gh run download -R quax-bot/quax-x-recorder -n capture-patch
git apply capture.patch   # at the root of QuaX
```

Modes:

- `ALL`: every link of `links.json`. Takes tens of minutes.
- `ONLY`: the links containing `value`.
- `NEW`: only the x.com link given as `value`, recorded as a temporary fixture. The patch holds only the files it created. For demos only, never merge it into QuaX, unless it has a `description`.

Options:

- `description` (`NEW` only): the description of the scenario, copied into its fixtures. The patch then also adds the link to `links.json`, with `"unstable": true`, so it can be committed to QuaX once reviewed.
- `screenshot` (`ONLY` and `NEW` only): the artifact also holds screenshots of each captured link, under `screenshots/`: the top of the page, then one per scroll, as the capture scrolls. A tweet page is taken whole. The page is opened again after the capture, so it may differ a little from the fixtures.

```bash
gh workflow run record.yml -R quax-bot/quax-x-recorder -f mode=NEW -f value=https://x.com/quax_tests/status/2096000000000000000 \
  -f description="Quote of a deleted post" -f screenshot=true
```

If the capture or a screenshot fails, the artifact is still uploaded and the job fails.

## Setup

1. Create an environment `main` and restrict its deployment branches to `master`. The `if` in the workflow is not enough, since a run from another branch uses that branch's workflow.
2. Add the secret `X_COOKIES` to it: the `cookie` request header of a logged-in x.com tab, copied whole from DevTools (Network, any request to x.com).

Use a throwaway X account, as X may lock it. When the session expires, log in again and update the secret.
