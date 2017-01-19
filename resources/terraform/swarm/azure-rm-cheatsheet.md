# Azure CLI Listing Cheatsheet

Install the Azure CLI package from NPM:

`npm install -g azure-cli`

Login by running

`azure login`

and following the on-screen prompts.

Azure CLI is basically a thin command-line wrapper around
the Azure Resource Manager API, so it's the best way to get
possible values for using ARM*, including in Terraform.

*ARM = Azure Resource Manager. That's going to be especially
confusing for you, considering your neighbours :)

## Locations

`azure location list`

Returns all locations available to your subscription. Shows the
short name and the display name; you need the short name, e.g. `northeurope`.

## VM sizes

This has to be done per-location:

`azure vm sizes --location northeurope`

You need the Name from there.

## VM images

These are really annoying, and they don't surface the info
in the web Marketplace. Grr.

Start out by listing the publishers:

`azure vm images list-publishers northeurope`

Once you've got the Publisher, you can get their offerings:

`azure vm images list-offers northeurope Canonical`

Then use the Offer property from there to get SKUs:

`azure vm images list-skus northeurope Canonical UbuntuServer`

Finally, to get the available versions, list the actual images:

`azure vm images list northeurope Canonical UbuntuServer 16.04.0-LTS`

Now you have all the values you need for the `azurerm_virtual_machine` resource.

