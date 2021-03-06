# Create all OS mounts specified in the extended metadata
class profile::os_mounts()
{
  echo {"Apply ${name}": withpath => false,}

  $disks = dig($::oci_instance, 'metadata', 'disk_info')
  if $disks {
    $disks.each |$name, $info| {
      $vg_name     = "vg_${name}"
      $lv_name     = "lv_${name}"
      $device      = $info['device']
      $mount_point = $info['mount_point']

      physical_volume { $device:
        ensure    => 'present',
        unless_vg => $vg_name,
      }
      ->volume_group { $vg_name:
        ensure           => present,
        physical_volumes => $device,
        createonly       => true,
      }
      logical_volume { $lv_name:
        ensure          => present,
        volume_group    => $vg_name,
        size_is_minsize => true,
      }
      -> filesystem { "/dev/${vg_name}/${lv_name}":
        ensure  => present,
        fs_type => 'xfs',
      }
      -> file { $mount_point:
        ensure  => directory,
        seltype => 'default_t',
        mode    => '0755',
      }
      -> mount { $mount_point:
        ensure => 'mounted',
        device => "/dev/mapper/${vg_name}-${lv_name}",
        dump   => '0',
        fstype => 'xfs',
        target => '/etc/fstab',
      }
    }
  } else {
    echo {"Skipping OCI volume processing...": withpath => false,}
  }
}
