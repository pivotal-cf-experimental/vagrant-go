maintainer       'Ivan Kusalic'
maintainer_email 'ivan@ikusalic.com'
description      'Wrapper cookbook for vagrant-go'

long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.3'

supports 'centos'

depends 'yum'
depends 'python'
