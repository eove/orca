{
  environment-target = "dev";
  has_dev_hack = true;
  latest_cvault = null;
  vm = {
    root_public_key = ./root_key.pub;
    simulated_yubikeys_folder = ./simulated-yubikeys;
  };
}
