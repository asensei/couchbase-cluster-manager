#!/usr/bin/ruby

require 'xcodeproj'

# Extract and check the arguments
# argv 1) The full path to the xcodeproj to be modified
# argv 2) The name of the organisation to be applied to the project
# argv 3) The name of the target to add the SwiftLint build phase to

project_path = ARGV[0]

if project_path == nil
    puts "ERROR: Require file path to xcode project file in 1st argument"
    exit
elsif !project_path.end_with?(".xcodeproj")
    puts "ERROR: Path doesn't include the correct file extension (.xcodeproj): #{project_path}"
    exit
elsif !File.exist?(project_path)
    puts "ERROR: Project not found at supplied project path: #{project_path}"
    exit
end

new_organisation_name = ARGV[1]

if new_organisation_name == nil
    puts "ERROR: Require organisation name in 2nd argument"
    exit
end

target_name = ARGV[2]

if target_name == nil
    puts "ERROR: Require target name in 3rd argument"
    exit
end

# Attempt to open the project

project = Xcodeproj::Project.open(project_path)

if project == nil
    puts "ERROR: Failed to open the project at path '#{project_path}'"
end

# Change the organisaiton name

old_organisation_name = project.root_object.attributes["ORGANIZATIONNAME"]

project.root_object.attributes["ORGANIZATIONNAME"] = new_organisation_name

puts "Changed organization name from '#{old_organisation_name}' to '#{new_organisation_name}'"

# Add the SwiftLint build phase to the target with the same name as the project

project.targets.each do |target|

    if target.name == target_name

        swiftlint_phase = target.new_shell_script_build_phase("SwiftLint")
        swiftlint_phase.shell_path = "/bin/sh"
        swiftlint_phase.shell_script = "if [ \"$CI\" = true ]; then\n    echo \"Skipping SwiftLint...\"\n    exit 0\nfi\n\nif which swiftlint >/dev/null; then\n    swiftlint\nelse\n    echo \"warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint\"\nfi"

        puts "Added Swift Lint build phase to '#{target_name}'"
    end
end

# Save the changes to the project

project.save

# Attempt to open the shared scheme

scheme_path = Xcodeproj::XCScheme.shared_data_dir(project.path) + "#{target_name}-Package.xcscheme"
scheme = Xcodeproj::XCScheme.new(scheme_path)

if scheme == nil
    puts "ERROR: Failed to open the shared scheme for target '#{target_name}'"
end

# Enable code coverage gathering on the scheme

scheme.test_action.code_coverage_enabled = true

# Save the changes to the scheme

scheme.save!
