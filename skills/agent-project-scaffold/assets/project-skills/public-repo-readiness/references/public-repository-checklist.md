# Public Repository Checklist

Use this reference after repository inspection and only apply the parts that
fit the project.

## Community files

GitHub's public community profile recognizes a README, license, contribution
guidelines, code of conduct, security policy, and valid issue templates. Keep
existing project-specific material and create missing files only after the
required facts are known.

- `LICENSE`: require an explicit choice. Use canonical license text and state
  the same license in the README. GitHub's [license guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)
  and [Choose a License](https://choosealicense.com/) explain the options; they
  are not legal advice.
- `CODE_OF_CONDUCT.md`: use a current, attributed community code of conduct and
  include a real enforcement contact. The [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/)
  is an appropriate default template only after that contact is known.
- `SECURITY.md`: name supported versions where known and provide a real private
  reporting route. Do not state that GitHub private vulnerability reporting is
  enabled unless it has been verified.
- `SUPPORT.md`: state the actual help route and what does not belong in support.
- Issue forms/templates and the pull-request template: request only information
  maintainers will use to triage reports and review changes.

See GitHub's [community-profile checklist](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)
for recognized locations and template requirements.

## README and badges

The README should give a first-time visitor the project purpose, value, setup,
use, help route, maintainer/contributor context, and links to the policy files.
Prefer a short README with links to deeper documentation.

Use only badges that describe an observable fact:

- GitHub Actions: use GitHub's official workflow badge URL for an existing
  workflow, constrained to the default branch when appropriate. Follow
  [GitHub's workflow badge documentation](https://docs.github.com/en/actions/how-tos/monitor-workflows/add-a-status-badge).
- License and latest-release badges require a public GitHub owner/repository and
  the corresponding artifact. Use a maintained badge provider and link each
  badge to the license or release page.
- OpenSSF Scorecard badges require published Scorecard results; link to the
  report, not an assumed score.

Do not add decorative popularity, download, coverage, security, or
"production-ready" badges.

## Conditional files and GitHub checklist

- `CODEOWNERS`: only with confirmed GitHub users or teams and an ownership need.
- `CITATION.cff`: only for software intended to be cited.
- `FUNDING.yml`: only with confirmed funding destinations.
- `GOVERNANCE.md`: only for projects with meaningful multi-maintainer governance.

After local files are ready, remind the maintainer to review the GitHub
repository description, website, topics, social-preview image, Community
Standards page, private vulnerability reporting, and public-repository security
features. This skill does not change those remote settings.
