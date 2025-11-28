{
  environment-target = "dev";
  has_dev_hack = true;
  latest_cvault = null;
  rotate_keys = false;
  actions_folder = ../example/actions;
  share_holder_keys_folder = ../example/share_holders_keys;
  actions_in_order = [
    #"create-root-CA"
    #"create-intermediate-CA"
    #"sign-csr"
    #"revoke-certificate"
  ];
  vm = {
    root_public_key = ./root_key.pub;
    simulated_yubikeys_folder = ./simulated-yubikeys;
  };
}
