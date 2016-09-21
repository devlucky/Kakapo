declared_trivial = github.pr_title.include? "#trivial"
has_source_changes = !git.modified_files.grep(/Source/).empty?
no_changelog_entry = !git.modified_files.include?("Changelog.md")

if has_source_changes && no_changelog_entry && !declared_trivial
  fail("Any changes to library code need a summary in the Changelog.")
end

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

# Don't let testing shortcuts get into master by accident
fail("fdescribe left in tests") if `grep -r fdescribe Tests/ `.length > 1
fail("fcontext left in tests") if `grep -r fcontext Tests/ `.length > 1
fail("fit left in tests") if `grep -r fit Tests/ `.length > 1

# If files are changed and test were not changed just warn
has_app_changes = !git.modified_files.grep(/Source/).empty?
has_test_changes = !git.modified_files.grep(/Tests/).empty?

if has_app_changes && !has_test_changes
  warn("Tests were not updated", sticky: false)
end

# swiftlint
swiftlint.lint_files

# markdown_files = (git.added_files + git.modified_files).select{ |file| file.end_with? "md" }
# prose.lint_files markdown_files
# prose.check_spelling markdown_files
