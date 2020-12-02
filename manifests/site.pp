## site.pp ##

# This file (./manifests/site.pp) is the main entry point
# used when an agent connects to a master and asks for an updated configuration.
# https://puppet.com/docs/puppet/latest/dirs_manifest.html
#
# Global objects like filebuckets and resource defaults should go in this file,
# as should the default node definition if you want to use it.

## Active Configurations ##

# Disable filebucket by default for all File resources:
# https://github.com/puppetlabs/docs-archive/blob/master/pe/2015.3/release_notes.markdown#filebucket-resource-no-longer-created-by-default
File { backup => false }

#
# Puppetserver actions
#
if $fqdn == $puppet_server {
  echo {'Puppetserver specific actions will be executed':
    withpath => false,
  }
  node_group {'OCI':
    ensure => present,
    parent => 'All Environments',
  }
  -> node_group {'management':
    ensure  => present,
    parent  => 'OCI',
    classes => {'profile::oci_management' => {}},
  }
}

#
# Fetch important OCI information about the instance for furher processing
#
$role                = dig($::oci_instance, 'metadata', 'role')
$additional_profiles = dig($::oci_instance, 'metadata', 'additional_profiles')
$disk_info           = dig($::oci_instance, 'metadata', 'disk_info') 

if $disk_info { contain profile::os_mounts }
#
# Include the selected role
#
if $role { 
  contain $role
  Class[::profile::os_mounts] -> Class[$role]
}
#
# And also include the selected additional profiles
#
if $additional_profiles { 
  $additional_profiles.each |$profile| {
    contain $profile
    Class[$role] -> Class[$profile]
  }
}
