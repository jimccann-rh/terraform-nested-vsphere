package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/url"
	"os"
	"path"
	"regexp"
	"strings"

	"github.com/AlecAivazis/survey/v2"
	"github.com/vmware/govmomi"
	"github.com/vmware/govmomi/find"
	content "github.com/vmware/govmomi/vapi/library"
	"github.com/vmware/govmomi/vapi/rest"
	"github.com/vmware/govmomi/vim25/soap"
)

type SurveyConfig struct {
	VCenters          []string `json:"vcenters"`
	ContentLibraryUrl string   `json:"esxiContentLibraryUrl"`
}

type Template struct {
	Version string  `json:"__version"`
	NewVcsa NewVcsa `json:"new_vcsa"`
	Ceip    Ceip    `json:"ceip"`
}
type VirtualCenter struct {
	Hostname          string   `json:"hostname"`
	Username          string   `json:"username"`
	Password          string   `json:"password"`
	DeploymentNetwork string   `json:"deployment_network"`
	Datacenter        []string `json:"datacenter"`
	Datastore         string   `json:"datastore"`
	Target            []string `json:"target"`
}
type Appliance struct {
	ThinDiskMode     bool   `json:"thin_disk_mode"`
	DeploymentOption string `json:"deployment_option"`
	Name             string `json:"name"`
}
type Network struct {
	IPFamily   string   `json:"ip_family"`
	Mode       string   `json:"mode"`
	SystemName string   `json:"system_name"`
	IP         string   `json:"ip"`
	Prefix     string   `json:"prefix"`
	Gateway    string   `json:"gateway"`
	DNSServers []string `json:"dns_servers"`
}
type OperatingSystem struct {
	Password      string `json:"password"`
	SSHEnable     bool   `json:"ssh_enable"`
	TimeToolsSync bool   `json:"time_tools_sync"`
}
type Sso struct {
	Password   string `json:"password"`
	DomainName string `json:"domain_name"`
}
type NewVcsa struct {
	VirtualCenter   `json:"vc"`
	Appliance       `json:"appliance"`
	Network         `json:"network"`
	OperatingSystem `json:"os"`
	Sso             `json:"sso"`
}
type Description struct {
}
type Settings struct {
	CeipEnabled bool `json:"ceip_enabled"`
}
type Ceip struct {
	Description `json:"description"`
	Settings    `json:"settings"`
}

type VCenterConnection struct {
	Client     *govmomi.Client
	Finder     *find.Finder
	Context    context.Context
	RestClient *rest.Client

	Uri      string
	Username string
	Password string

	TerraformEsxiVariables TerraformEsxiVariables
}

type TerraformEsxiVariables struct {
	VSphereUser            string `json:"vsphere_user"`
	VSpherePassword        string `json:"vsphere_password"`
	VSphereServer          string `json:"vsphere_server"`
	ContentLibraryName     string `json:"content_library_name"`
	ContentLibraryItemName string `json:"content_library_item_name"`
	VSphereDatacenter      string `json:"vsphere_datacenter"`
	VSphereCluster         string `json:"vsphere_cluster"`
	VSphereResourcePool    string `json:"vsphere_resource_pool"`
	VSphereDatastore       string `json:"vsphere_datastore"`
	VSphereNetwork         string `json:"vsphere_network"`
	VSphereEsxiHost        string `json:"vsphere_esxi_host"`
	EsxiOvaUrl             string `json:"esxi_ova_url"`
}

func getVCenterClient(config *SurveyConfig) (*VCenterConnection, error) {
	var uri, username, password string
	var surveyPromptVCenter survey.Prompt
	ctx := context.Background()

	connection := &VCenterConnection{
		Context: ctx,
	}

	if len(config.VCenters) == 0 {
		surveyPromptVCenter = &survey.Input{
			Message: "vCenter",
		}

	} else {
		surveyPromptVCenter = &survey.Select{
			Message: "vCenter",
			Options: config.VCenters,
		}
	}

	survey.Ask([]*survey.Question{
		{
			Prompt: surveyPromptVCenter,
		},
	}, &uri)

	survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Input{
				Message: "username",
				Default: "Administrator@devqe.ibmc.devcluster.openshift.com",
			},
		},
	}, &username)

	/*
		survey.Ask([]*survey.Question{
			{
				Prompt: &survey.Password{
					Message: "password",
				},
			},
		}, &password)

	*/
	password = "R3dhatR3dhat!"

	connection.TerraformEsxiVariables.VSphereUser = username
	connection.TerraformEsxiVariables.VSpherePassword = password
	connection.TerraformEsxiVariables.VSphereServer = uri

	u, err := soap.ParseURL(uri)
	if err != nil {
		return nil, err
	}
	connection.Username = username
	connection.Password = password
	connection.Uri = uri

	u.User = url.UserPassword(username, password)

	c, err := govmomi.NewClient(ctx, u, true)
	if err != nil {
		return nil, err
	}

	connection.RestClient = rest.NewClient(c.Client)

	err = connection.RestClient.Login(connection.Context, u.User)
	if err != nil {
		return nil, err
	}
	connection.Client = c
	return connection, nil

}

func createTemplate(connection *VCenterConnection) (*Template, error) {
	var datacenterNames, clusterNames, portGroupNames []string
	var selectedDatastore, selectedDatacenter, selectedCluster, selectedPortGroup, selectedHost string

	datacenters, err := connection.Finder.DatacenterList(connection.Context, "/...")
	if err != nil {
		return nil, err
	}
	for _, dc := range datacenters {
		datacenterNames = append(datacenterNames, dc.Name())
	}

	survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Select{
				Message: "Datacenter",
				Options: datacenterNames,
			},
		},
	}, &selectedDatacenter)

	connection.TerraformEsxiVariables.VSphereDatacenter = selectedDatacenter

	clusterQuery := path.Join("/", selectedDatacenter, "...")

	clusters, err := connection.Finder.ClusterComputeResourceList(connection.Context, clusterQuery)
	if err != nil {
		return nil, err
	}

	clusterHosts := make(map[string][]string)
	clusterDatastores := make(map[string][]string)
	for _, c := range clusters {

		clusterNames = append(clusterNames, c.Name())
		hosts, err := c.Hosts(connection.Context)

		if err != nil {
			return nil, err
		}

		datastores, err := c.Datastores(connection.Context)
		if err != nil {
			return nil, err
		}

		for _, h := range hosts {
			clusterHosts[c.Name()] = append(clusterHosts[c.Name()], h.Name())
		}

		for _, ds := range datastores {
			dsName, err := ds.ObjectName(connection.Context)
			if err != nil {
				return nil, err
			}
			clusterDatastores[c.Name()] = append(clusterDatastores[c.Name()], dsName)
		}

	}

	survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Select{
				Message: "Cluster",
				Options: clusterNames,
			},
		},
	}, &selectedCluster)
	connection.TerraformEsxiVariables.VSphereCluster = selectedCluster

	survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Select{
				Message: "Host",
				Options: clusterHosts[selectedCluster],
			},
		},
	}, &selectedHost)

	connection.TerraformEsxiVariables.VSphereEsxiHost = selectedHost

	survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Select{
				Message: "Host",
				Options: clusterDatastores[selectedCluster],
			},
		},
	}, &selectedDatastore)

	connection.TerraformEsxiVariables.VSphereDatastore = selectedDatastore

	//networkQuery := path.Join("/", selectedDatacenter, "host", selectedCluster)
	networkQuery := path.Join("/", selectedDatacenter, "/...")

	networks, err := connection.Finder.NetworkList(connection.Context, networkQuery)

	if err != nil {
		return nil, err
	}

	for _, n := range networks {
		// ignore everything except dvpg
		ref := n.Reference()
		switch ref.Type {
		case "Network":
		case "DistributedVirtualSwitch", "VmwareDistributedVirtualSwitch":
		case "OpaqueNetwork":
			continue
		case "DistributedVirtualPortgroup":
			portGroupNames = append(portGroupNames, path.Base(n.GetInventoryPath()))
		}
	}
	survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Select{
				Message: "Port Group",
				Options: portGroupNames,
			},
		},
	}, &selectedPortGroup)
	connection.TerraformEsxiVariables.VSphereNetwork = selectedPortGroup

	return nil, nil

}

func setFinder(connection *VCenterConnection) {
	connection.Finder = find.NewFinder(connection.Client.Client, true)
}

func readConfig() (*SurveyConfig, error) {

	surveyConfig := &SurveyConfig{}

	configBytes, err := os.ReadFile("config/config.json")
	if err != nil {
		return nil, err
	}
	err = json.Unmarshal(configBytes, surveyConfig)
	if err != nil {
		return nil, err
	}

	return surveyConfig, nil

}

func readContentLibrary(connection *VCenterConnection, name string) error {
	var selectedEsxiVersion string

	manager := content.NewManager(connection.RestClient)

	library, err := manager.GetLibraryByName(connection.Context, name)
	if err != nil {
		return err
	}

	libraryItems, err := manager.GetLibraryItems(connection.Context, library.ID)
	if err != nil {
		return err
	}

	var nestedAppliances []string
	libraryItemsToVersion := make(map[string]content.Item)

	//libraryItemsFiles := make(map[string][]content.File)

	for _, i := range libraryItems {
		//fmt.Printf("%s, %s, %s", i.Name, i.Version, i.Description)

		re := regexp.MustCompile("Nested_(.*?)_Appliance.*")
		matches := re.FindStringSubmatch(i.Name)
		// there should be only two, the original string and the group
		if len(matches) == 2 {
			version := matches[1]
			nestedAppliances = append(nestedAppliances, version)
			libraryItemsToVersion[version] = i
		}
	}

	survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Select{
				Message: "ESXi Version",
				Options: nestedAppliances,
			},
		},
	}, &selectedEsxiVersion)

	item := libraryItemsToVersion[selectedEsxiVersion]
	libraryItemsFiles, err := manager.ListLibraryItemFiles(connection.Context, item.ID)

	if err != nil {
		return err
	}

	for _, f := range libraryItemsFiles {
		parts := strings.Split(f.Name, ".ovf")
		if len(parts) != 1 {
			connection.TerraformEsxiVariables.EsxiOvaUrl = fmt.Sprintf("https://download3.vmware.com/software/vmw-tools/nested-esxi/%s.ova", parts[0])
			break
		}
	}

	/*

		var session string
		//var info []*content.DownloadFile

		expirationTime := time.Now().Add(time.Hour)

		session, err = manager.CreateLibraryItemDownloadSession(connection.Context,
			content.Session{
				LibraryItemID:  item.ID,
				ExpirationTime: &expirationTime,
			},
		)
		if err != nil {
			return err
		}

		for _, f := range libraryItemsFiles {
			_, err := manager.PrepareLibraryItemDownloadSessionFile(connection.Context, session, f.Name)
			if err != nil {
				return err
			}
		}
		var downloadFiles []content.DownloadFile

		for {
			allPrepared := true
			downloadFiles, err = manager.ListLibraryItemDownloadSessionFile(connection.Context, session)
			//info, err = manager.GetLibraryItemDownloadSessionFile(connection.Context, session, name)
			if err != nil {
				return err
			}
			for _, df := range downloadFiles {
				if df.Status != "PREPARED" {
					allPrepared = false
					break
				}
			}
			if allPrepared {
				break // with this status we have a DownloadEndpoint.URI
			}

			time.Sleep(time.Second)
		}

		for _, df := range downloadFiles {
			fmt.Println(df.DownloadEndpoint.URI)
		}

		for {

			time.Sleep(time.Second * 60)
		}

	*/
	//src, err := url.Parse(info.DownloadEndpoint.URI)

	//fmt.Println(src.String())

	/*
		err = manager.CancelLibraryItemUpdateSession(connection.Context, session)

		if err != nil {
			return err
		}

	*/

	return nil

}

func main() {
	config, err := readConfig()

	if err != nil {
		log.Fatal(err)
	}

	connection, err := getVCenterClient(config)

	if err != nil {
		log.Fatal(err)
	}
	setFinder(connection)

	_, err = createTemplate(connection)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(connection.Uri)
	err = readContentLibrary(connection, "nested")
	if err != nil {
		log.Fatal(err)
	}

	terraformVars, err := json.MarshalIndent(connection.TerraformEsxiVariables, "", "  ")

	if err != nil {
		log.Fatal(err)
	}
	err = os.WriteFile("variables.json", terraformVars, 0644)
	if err != nil {
		log.Fatal(err)
	}

	/*
		template := Template{
			Version: "",
			NewVcsa: NewVcsa{},
			Ceip:    Ceip{},
		}
		templateBytes, err := json.MarshalIndent(template, "", " ")

		if err != nil {

		}

	*/

}
