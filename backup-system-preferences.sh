#!/usr/bin/env bash
#
# TODO
# - Allow parameters to chose the Mackup storage engine/directory
#
#

function show_usage {
printf  "usage: %s [option] action\n" "$0"
cat << 'EOF'
options:
       -d directory   Destination directory to store the lists
       -r repo_url    repo url for Macpref installation
       -m directory   path for Macpref installation directory
       -h             Print help
action:
       backup         Export system config file with Macprefs
       restore        Restore system config file with Macprefs
       install        Install Macprefs without any further action
EOF
  return 0
}

function setup_environment {
  [[ -z $macprefs_repo ]] && macprefs_repo='https://github.com/clintmod/macprefs'
  [[ -z $macprefs_dir ]] && macprefs_dir='./macprefs'
  [[ -z $backup_dir ]] && backup_dir='./system_preferences' # default destination if no '-d' is specified
  macprefs_tool="${macprefs_dir}/macprefs"
}

function install_macprefs {
  local temp_dir
  temp_dir=$(mktemp -d)
  macprefs_archive='macprefs.zip'
  macprefs_archive_url="$macprefs_repo/archive/master.zip"

  printf "Installing a local copy of Macprefs\n"

  printf "Downloading Macprefs into '%s/%s'\n" "$temp_dir" "$macprefs_archive"
  curl -H 'Cache-Control: no-cache' -fsSL "$macprefs_archive_url" -o "${temp_dir}/${macprefs_archive}" || exit 1

  printf "Decompressing Macprefs archive into '%s'\n" "$temp_dir"
  unzip -qq "${temp_dir}/${macprefs_archive}" -d "${temp_dir}" || exit 1

  printf "Installing Macprefs files to '%s'\n" "$macprefs_dir"
  [[ ! -d $macprefs_dir ]] && mkdir -p "$macprefs_dir"

  rsync --exclude .git --exclude .gitmodules --exclude .gitignore --exclude .travis.yml --exclude test/ -rlWuv "$temp_dir"/*/* "$macprefs_dir" || exit

  printf "Removing temporary files\n"
  rm -rf "$temp_dir" || exit

  printf "Installation successful!\n"

}

function run_macprefs {
  local action="$1"
  local macprefs_log="${macprefs_dir}/macprefs.log"
  if [[ $action == 'restore' ]] && [[ ! -d $backup_dir ]]; then
      printf ">>>>>>>>>> Error: Backup dir '%s' is not available" "${backup_dir}"
      exit 1
  fi
  if [[ -x $macprefs_tool ]]; then
    #  Any preferences Mackup backs up won't be backed up by Macprefs
    printf "Running macprefs $action using '%s'..." "${backup_dir}"
    MACPREFS_BACKUP_DIR="$backup_dir" eval "$macprefs_tool" -v "$action" > "$macprefs_log" 2>&1
    printf "   done!\n"
  else
    printf ">>>>>>>>>> Error: %s is not available or executable" "${macprefs_tool}"
    exit 1
  fi
}

function main {
  while getopts ":d:r:m:h" option; do
    case "$option" in
      d)
        backup_dir="$OPTARG"
        ;;
      r)
        macprefs_repo="$OPTARG"
        ;;
      m)
        macprefs_dir="$OPTARG"
        ;;
      h)
        show_usage
        exit 0
        ;;
      \?)
        echo ">>>>>>>>>> Error: Invalid option: $OPTARG." 1>&2
        exit 1
        ;;
      :)
        echo ">>>>>>>>>> Error: Missing argument for option: '-${OPTARG}'." 1>&2
        exit 1
        ;;
    esac
  done
  #
  shift $(( OPTIND - 1 ))
  action="$1"; shift
  if [[ -n $* ]];then
    echo ">>>>>>>>>> Error: Provided unknow parameter: $1" 1>&2
    exit 1
  fi
  case "$action" in
    backup)
      action_requested="backup"
      ;;
    restore)
      action_requested="restore"
      ;;
    install)
      # will install macprefs without triggering any action
      ;;
    '')
      echo ">>>>>>>>>> Error: Missing action" 1>&2
      show_usage
      exit 1
      ;;
    *)
      echo ">>>>>>>>>> Error: Invalid action '$action'" 1>&2
      exit 1
      ;;
  esac

  setup_environment
  if [[ ! -x $macprefs_tool ]]; then
    install_macprefs  1>&2
  elif [[ -z $action_requested ]]; then
    echo ">>>>>>>>>> Macprefs is already installed" 1>&2
  fi
  [[ -n $action_requested ]] && run_macprefs "$action_requested"
  exit 0
}

main "$@"
