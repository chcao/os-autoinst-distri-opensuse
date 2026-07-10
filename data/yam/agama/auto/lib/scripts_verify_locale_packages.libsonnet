{
  name: 'verify cz locale packages',
  chroot: true,
  content: |||
    if rpm -q glibc-locale-base autoyast2; then
      echo "LOCALE_CHECK_PASSED" > /root/locale_check.result
    else
      echo "LOCALE_CHECK_FAILED" > /root/locale_check.result
    fi
  |||,
},
