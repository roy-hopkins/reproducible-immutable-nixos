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

  # Enable Hyper-V guest services
  services.hypervkvpd.enable = true;
  services.hypervvssd.enable = true;
  services.hypervfcopyd.enable = true;

  # Configure network for Hyper-V
  systemd.network = {
    networks."10-ethernet" = {
      matchConfig.Name = "eth*";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      dhcpV4Config = {
        UseDNS = true;
        UseRoutes = true;
      };
    };
  };

  # Hyper-V specific kernel parameters
  boot.kernelParams = [
    # Remove the serial console parameter from base.nix since Hyper-V uses different console
    # We'll override this in the base configuration
  ];

  # Override the serial console setting from base.nix for Hyper-V
  boot.kernelParams = [
    # Hyper-V uses different console
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  # Enable integration services
  virtualisation.hypervGuest.enable = true;
}