#!/usr/bin/env bash
#
# TODO
# - Allow parameters to chose the Mackup storage engine/directory
#
#

function show_usage {
printf  "usage: %s [option] object\n" "$0"
cat << 'EOF'
options:
       -d  path/to/dest/dir           Destination directory to store the lists
       --help                         Print help
object:
       brew [taps|packages|casks|all] Export list of brew taps, packages and casks
       ruby [gems]                    Export list of user installed Ruby gems
       mas [packages]                 Export list of installed apps from MacAppStore
       npm [packages]                 Export list of NPM packages
       pip [packages]                 Export list of user installed Python packages from Pip
       all                            Export all the above
EOF
  return 0
}

function setup_environment {
  [[ -z $destination_dir ]] && destination_dir='.' # default destination if no '-d' is specified
  homebrew_taps_list_file="${destination_dir}/homebrew_taps.txt"
  homebrew_packages_list_file="${destination_dir}/homebrew_packages.txt"
  homebrew_cask_apps_list_file="${destination_dir}/homebrew_cask_apps.txt"
  mas_apps_list_file="${destination_dir}/mas_apps.txt"
  npm_global_packages_list_file="${destination_dir}/npm_global_packages.json"
  pip_packages_list_file="${destination_dir}/pip_packages.txt"
  ruby_gems_list_file="${destination_dir}/ruby_gems.txt"
}

function export_homebrew_taps {
  if command -v brew >/dev/null 2>&1; then
    printf "Exporting Homebrew Taps list to %s..." "${homebrew_taps_list_file}"
    brew tap-info --installed | grep -v -e '^$' | grep -v 'From\|files' | cut -d: -f1 > "${homebrew_taps_list_file}"
    printf " done!\n"
  else
    printf ">>>>>>>>>> Error: brew is not installed"
    exit 1
  fi
}

function export_homebrew_packages {
  if command -v brew >/dev/null 2>&1; then
    printf "Exporting Homebrew Packages list to %s..." "${homebrew_packages_list_file}"
    brew list | grep '^[0-9]' -v > "${homebrew_packages_list_file}"
    printf " done!\n"
  else
    printf ">>>>>>>>>> Error: brew is not installed"
    exit 1
  fi
}

function export_homebrew_cask {
  if command -v brew >/dev/null 2>&1; then
    printf "Exporting Homebrew Casks list to %s..." "${homebrew_cask_apps_list_file}"
    brew list --cask | grep '^[0-9]' -v > "${homebrew_cask_apps_list_file}"
    printf " done!\n"
  else
    printf ">>>>>>>>>> Error: brew is not installed"
    exit 1
  fi
}

function export_homebrew_all {
  export_homebrew_taps
  export_homebrew_packages
  export_homebrew_cask
}

function export_mas_apps {
  if command -v mas; then
    printf "Exporting MacAppStore apps list to %s..." "${mas_apps_list_file}"
    mas list | sed 's/ /,/' > "${mas_apps_list_file}"
    # returns list like:
    # ID,Name (version)
    # 402415186,GarageBuy (3.4)
    # ...
    printf " done!\n"
  else
    printf ">>>>>>>>>> Error: mas is not installed"
    exit 1
  fi
}

function export_npm_global_packages {
  if command -v npm >/dev/null 2>&1; then
    printf "Exporting NPM Global packages list to %s..." "${npm_global_packages_list_file}"
    npm list -g --depth=0 --json > "${npm_global_packages_list_file}"
    # returns list like:
    # {
    #   "dependencies": {
    #     "gulp": {
    #       "version": "4.0.2",
    #       "from": "gulp@latest",
    #       "resolved": "https://registry.npmjs.org/gulp/-/gulp-4.0.2.tgz"
    #     },
    #     ""yarn"": {
    #       ...
    #     }
    #   }
    # }
    printf " done!\n"
  else
    printf ">>>>>>>>>> Error: npm is not installed"
    exit 1
  fi
}

function export_pip_packages {
  if command -v pip >/dev/null 2>&1; then
    printf "Exporting PIP packages list to %s..." "${pip_packages_list_file}"
    pip list -o --format freeze  2> /dev/null | sed 's/==/,/'  > "${pip_packages_list_file}"
    # returns list like:
    # package==version
    # ...
    printf " done!\n"
  else
    printf ">>>>>>>>>> Error: pip is not installed"
    exit 1
  fi
}

function export_ruby_user_gems {
  if command -v gem >/dev/null 2>&1; then
    printf "Exporting Ruby gems list to %s..." "${ruby_gems_list_file}"
    gem list | grep -v 'default' |  sed 's/[(,)]//g' | cut -d "," -f1 | sed 's/ /,/g'  > "${ruby_gems_list_file}"
    # returns list like:
    # gem,version
    # ...
    printf " done!\n"
  else
    printf ">>>>>>>>>> Error: gem is not installed"
    exit 1
  fi
}

function export_all {
  export_homebrew_all
  export_mas_apps
  export_npm_global_packages
  export_pip_packages
  export_ruby_user_gems
}

function option_error {
  echo ">>>>>>>>>> Error: Invalid option '$object_option' for export object '$object' " 1>&2
  exit 1
}

function main {
  case "$1" in
    -d|--directory)
      destination_dir="$2"
      shift 2
      ;;
    --help)
      show_usage
      exit 0
      ;;
    -*)
      echo ">>>>>>>>>> Error: Invalid option: $1." 1>&2
      exit 1
      ;;
  esac

  object="$1";
  object_option=$2; # fetch the action's option
  case "$object" in
    brew|homebrew)
      # Process package options
      case $object_option in
        taps)
          export_requested="export_homebrew_taps"
          ;;
        casks)
          export_requested="export_homebrew_cask"
          ;;
        packages)
          export_requested="export_homebrew_packages"
          ;;
        all|'')
          export_requested="export_homebrew_all"
          ;;
        *)
          export_requested="option_error"
          ;;
        esac
      ;;
    npm)
      # Process package options
      case $object_option in
        packages|'')
          export_requested="export_npm_global_packages"
          ;;
        *)
          export_requested="option_error"
          ;;
        esac
      ;;
    pip)
      # Process package options
      case $object_option in
        packages|'')
          export_requested="export_pip_packages"
          ;;
        *)
          export_requested="option_error"
          ;;
        esac
      ;;
    ruby|gems)
      # Process package options
      case $object_option in
        gems|'')
          export_requested="export_ruby_user_gems"
          ;;
        *)
          export_requested="option_error"
          ;;
        esac
      ;;
    mas)
      # Process package options
      case $object_option in
        packages|'')
          export_requested="export_mas_apps"
          ;;
        *)
          export_requested="option_error"
          ;;
        esac
      ;;
    all)
      export_requested="export_all"
      ;;
    help)
      export_requested="show_usage"
      ;;
    '')
      echo ">>>>>>>>>> Error: Missing export object" 1>&2
      exit 1
      ;;
    *)
      echo ">>>>>>>>>> Error: Invalid export object '$object'" 1>&2
      exit 1
      ;;
  esac

  setup_environment
  [[ -n $export_requested ]] && eval "$export_requested"
  exit 0
}

main "$@"
