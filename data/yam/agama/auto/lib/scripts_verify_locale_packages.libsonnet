[
  {
    name: 'verify_locale_packages',
    chroot: true,
    body: |||
      #!/bin/bash
      set -euo pipefail

      # Verify glibc-locale package is installed
      rpm -q glibc-locale

      # Verify system language configuration
      grep -q "^LANG=cs_CZ.utf8" /etc/locale.conf
    |||,
  },
]
