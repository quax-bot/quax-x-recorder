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
- `NEW`: only the x.com link given as `value`, recorded as a temporary fixture. The patch holds only the files it created. For demos only, never merge it into QuaX.

If the capture fails, the patch is still uploaded and the job fails.

## Setup

1. Create an environment `main` and restrict its deployment branches to `master`. The `if` in the workflow is not enough, since a run from another branch uses that branch's workflow.
2. Add the secret `X_COOKIES` to it: the `cookie` request header of a logged-in x.com tab, copied whole from DevTools (Network, any request to x.com).

Use a throwaway X account, as X may lock it. When the session expires, log in again and update the secret.
