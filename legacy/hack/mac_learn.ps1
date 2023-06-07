
# Source:
# https://fojta.wordpress.com/2020/07/06/enable-mac-learning-as-default-on-vsphere-distributed-switch/



$vds = get-vdswitch 'DSwitch0'
$spec = New-Object VMware.Vim.VMwareDVSConfigSpec
$spec.DefaultPortConfig = New-Object VMware.Vim.VMwareDVSPortSetting
$spec.DefaultPortConfig.MacManagementPolicy = New-Object VMware.Vim.DVSMacManagementPolicy
$spec.DefaultPortConfig.MacManagementPolicy.MacLearningPolicy = New-Object VMware.Vim.DVSMacLearningPolicy

$spec.DefaultPortConfig.MacManagementPolicy.MacLearningPolicy.Enabled = $True
$spec.DefaultPortConfig.MacManagementPolicy.MacLearningPolicy.AllowUnicastFlooding = $True
$spec.DefaultPortConfig.MacManagementPolicy.MacLearningPolicy.Limit = 4000
$spec.DefaultPortConfig.MacManagementPolicy.MacLearningPolicy.LimitPolicy = "DROP"
$vds.ExtensionData.ReconfigureDvs_Task($spec)
