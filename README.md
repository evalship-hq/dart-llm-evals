# LLM evals for Dart and Flutter

A Dart support bot whose AI call is tested on every pull request with [tinyeval](https://tinyeval.com).

## Run it

Clone this repo, or use it as a template. Then:

```sh
dart pub get
export ANTHROPIC_API_KEY=sk-ant-...
./tinyeval
```

```
support
  ✓ refund after the window 6.2s
  ✓ missing package 5.1s
  ✓ refund inside the window 5.5s

All 3 evals passed (eval-results.json)
```

## What's here

- `lib/support.dart`: the bot. `Support.answer(message)` sends the message to Claude and returns the reply. Dart has no official Anthropic SDK, so it calls the Messages API with `package:http`.
- `prompts/support.md`: the system prompt.
- `bin/evalworker.dart`: the tinyeval worker. It builds `Support` once, then answers each test case.
- `evals/support.sh`: three test cases, checked with a regex, a model judge or both.
- `tinyeval`: the eval runner, one bash file.
- `.github/workflows/evals.yml`: runs the evals on every pull request and on pushes to main.

## Use it for your app

1. Replace `answer` with your AI call. Keep the worker, so your app starts once per worker and not once per test case.
2. Write your test cases in `evals/`. The [check lines](https://github.com/evalship-hq/tinyeval#writing-evals) cover regexes, JSON, your own graders and a model judge.
3. In a Flutter app, keep the AI call in plain Dart with no Flutter imports, in a file under `lib/` or in its own package. The worker then runs it with the Dart VM, without a device or emulator.

When the API call fails for a reason that isn't your code, such as a missing key, a rate limit or a timeout, the worker replies `#tinyeval couldnt_run`. tinyeval then counts the test case as couldn't run, not as failed. Keep that split when you swap in your own client.

## In CI

Add `ANTHROPIC_API_KEY` as a repository secret under **Settings** > **Secrets and variables** > **Actions**. tinyeval's judge uses the same key.

The workflow installs the packages, cached by `pubspec.lock`, then runs each test case 3 times. A test case passes when at least 2 of the 3 runs pass. A failing eval fails the job, so you can require it before merging. The results go up as the `eval-results` artifact, also when an eval fails.

Without the secret, the workflow skips the evals and prints a notice. Pull requests from forks get no secrets, so their evals skip too.

## Compare pull requests with main

A fresh CI run has no earlier run to compare with. [evalship](https://evalship.com) reads `eval-results.json`, compares each pull request with main, tells flaky evals from real drops and comments on the pull request.

## License

MIT. See [LICENSE](LICENSE).
