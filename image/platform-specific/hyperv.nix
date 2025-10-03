{
  ...
}:
{
  # Enable Hyper-V guest services and kernel modules
  boot.initrd.availableKernelModules = [
    # Hyper-V storage and network drivers
    "hv_storvsc"
    "hv_netvsc"
    "hv_vmbus"
    "hv_utils"
    "hv_balloon"
  ];

  boot.kernelModules = [
    # Additional Hyper-V modules
    "hv_sock"
  ];

  # Note: Individual Hyper-V services are managed by virtualisation.hypervGuest.enable

  # Configure network for Hyper-V
  systemd.network = {
    networks."10-ethernet" = {
      matchConfig.Name = "eth*";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
      };
      dhcpV4Config = {
        UseDNS = true;
        UseRoutes = true;
      };
    };
  };

  # Override the serial console setting from base.nix for Hyper-V
  boot.kernelParams = [
    # Hyper-V uses different console
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  # Enable integration services
  virtualisation.hypervGuest.enable = true;
}