{
  product: {
    id: 'openSUSE_Leap'
  },
  bootloader: {
    stopOnBootMenu: true,
  },
  user: {
    fullName: 'Bernhard M. Wiedemann',
    password: '$6$vYbbuJ9WMriFxGHY$gQ7shLw9ZBsRcPgo6/8KmfDvQ/lCqxW8/WnMoLCoWGdHO6Touush1nhegYfdBbXRpsQuy/FTZZeg7gQL50IbA/',
    hashedPassword: true,
    userName: 'bernhard'
  },
  root: {
    password: '$6$vYbbuJ9WMriFxGHY$gQ7shLw9ZBsRcPgo6/8KmfDvQ/lCqxW8/WnMoLCoWGdHO6Touush1nhegYfdBbXRpsQuy/FTZZeg7gQL50IbA/',
    hashedPassword: true,
  },
  scripts: {
    pre: [
      {
        content: '#!/usr/bin/env bash\nfor i in `lsblk -n -l -o NAME -d -e 7,11,254`\n    do wipefs -af /dev/$i\n    sleep 1\n    sync\ndone\n',
        name: 'wipefs',
      },
    ],
  },
}
