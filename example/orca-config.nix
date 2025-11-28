{
  environment-target = "preprod";
  latest_cvault = null;
  rotate_keys = false;
  actions_folder = ./actions;
  share_holder_keys_folder = ./share_holders_keys;
  actions_in_order = [
    #"create-root-CA"
    #"create-intermediate-CA"
    #"sign-csr"
    #"revoke-certificate"
  ];
}
