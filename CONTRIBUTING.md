# Contributing to ProcessSettings

This document explains our guidelines and workflows to contributing to an Invoca open source project.  Please take care to follow the guidelines, as they exist to help us manage changes in a timely and efficient manner.

## Code of Conduct
All contributors to this project must adhere to the [Community Code of Conduct](https://github.com/Invoca/process_settings/blob/master/code-of-conduct.md)

## Environment Setup
1. Install the ruby version specified in the [.ruby-version](https://github.com/Invoca/process_settings/blob/master/.ruby-version) file (preferably you're using [rvm](https://rvm.io/) or [rbenv](https://github.com/rbenv/rbenv) to manage ruby versions)
2. Make a fork of ProcessSettings, then clone your fork to your machine
3. Run `bundle install` in your ProcessSettings directory to install dependencies
4. Run `mkdir tmp` (if it doesn't already exist). This is needed to run the tests.

## Branching

* __Create an issue before starting a branch__
* For bugs, prefix the branch name with `bug/`
* For features, prefix the branch name with `feature/`
* Include the issue number and a short description of the issue

Examples 
* `bug/1234_fix_issue_with_formatter_not_formatting`
* `feature/4321_merge_contexts_together`

## Filing Issues

* Use the appropriate template provided
* Include as much information as possible to help:
  * The person who will be fixing the bug understand the issue
  * The person code reviewing the fix to understand what the original need was
* Check for open issues before filing your own

## Committing

* Break your commits into logical atomic units. Well-segmented commits make it much easier for others to step through your changes.
* Limit your subject (first) line to 50 characters (GitHub truncates more than 70).
* Provide a body if you'd like to explain your commit in detail.
* Capitalize the beginning of your subject line, and do not end the subject line with a period.
* Your subject line should complete this sentence: `If applied, this commit will [your subject line]`.
* Don't use [magic GitHub words](https://help.github.com/articles/closing-issues-using-keywords/) in your commits to close issues - do that in the pull request for your code instead.
* Adapted from [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/#seven-rules).

## Making Pull Requests

* Use fill out the template provided
* Provide a link to the issue being resolved by the PR
* Make sure to include tests
* Resolve linting comments from Hound before requesting review
