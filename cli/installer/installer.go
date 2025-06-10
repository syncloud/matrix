package installer

import (
	"fmt"
	"github.com/google/uuid"
	cp "github.com/otiai10/copy"
	"github.com/syncloud/golib/config"
	"github.com/syncloud/golib/linux"
	"github.com/syncloud/golib/platform"
	"go.uber.org/zap"

	"os"
	"path"
)

const App = "matrix"

type Variables struct {
	AppDir       string
	DataDir      string
	CommonDir    string
	DatabaseDir  string
	DatabasePort int
	Domain       string
}

type Installer struct {
	newVersionFile     string
	currentVersionFile string
	configDir          string
	platformClient     *platform.Client
	database           *Database
	installFile        string
	executor           *Executor
	appDir             string
	dataDir            string
	commonDir          string
	logger             *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	appDir := fmt.Sprintf("/snap/%s/current", App)
	dataDir := fmt.Sprintf("/var/snap/%s/current", App)
	commonDir := fmt.Sprintf("/var/snap/%s/common", App)
	configDir := path.Join(dataDir, "config")
	executor := NewExecutor(logger)
	return &Installer{
		newVersionFile:     path.Join(appDir, "version"),
		currentVersionFile: path.Join(dataDir, "version"),
		configDir:          configDir,
		platformClient:     platform.New(),
		database:           NewDatabase(appDir, dataDir, configDir, App, executor, logger),
		installFile:        path.Join(commonDir, "installed"),
		executor:           executor,
		appDir:             appDir,
		dataDir:            dataDir,
		commonDir:          commonDir,
		logger:             logger,
	}
}

func (i *Installer) Install() error {

	err := i.executor.Run(
		path.Join(i.appDir, "matrix/bin/generate-keys"),
		"--private-key",
		path.Join(i.dataDir, "private_key.pem"),
	)
	if err != nil {
		return err
	}

	err = i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.database.Init()
	if err != nil {
		return err
	}
	err = i.database.InitConfig()
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) Configure() error {
	if i.IsInstalled() {
		err := i.Upgrade()
		if err != nil {
			return err
		}
	} else {
		err := i.Initialize()
		if err != nil {
			return err
		}
	}

	err := i.FixPermissions()
	if err != nil {
		return err
	}

	return i.UpdateVersion()
}

func (i *Installer) IsInstalled() bool {
	_, err := os.Stat(i.installFile)
	return err == nil
}

func (i *Installer) Initialize() error {
	err := i.StorageChange()
	if err != nil {
		return err
	}

	err = i.database.Execute(
		"postgres",
		fmt.Sprintf("ALTER USER %s WITH PASSWORD '%s'", App, App),
	)
	if err != nil {
		return err
	}
	err = i.CreateDBs()
	if err != nil {
		return err
	}
	err = i.database.Execute("postgres", fmt.Sprintf("GRANT CREATE ON SCHEMA public TO %s", App))
	if err != nil {
		return err
	}
	err = i.SetSyncSecret()
	if err != nil {
		return err
	}
	err = i.MarkInstalled()
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) CreateDBs() error {
	dbs := []string{
		"matrix",
		"sync",
		"whatsapp",
		"telegram",
		"signal",
		"signald",
		"slack",
		"discord",
	}
	for _, db := range dbs {
		err := i.database.createDbIfMissing(db)
		if err != nil {
			return err
		}
	}
	return nil
}

func (i *Installer) MarkInstalled() error {
	return os.WriteFile(i.installFile, []byte("installed"), 0644)
}

func (i *Installer) Upgrade() error {
	err := i.database.Restore()
	if err != nil {
		return err
	}
	err = i.StorageChange()
	if err != nil {
		return err
	}
	err = i.CreateDBs()
	if err != nil {
		return err
	}
	err = i.SetSyncSecret()
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) PreRefresh() error {
	return i.database.Backup()
}

func (i *Installer) PostRefresh() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}
	err = i.database.Remove()
	if err != nil {
		return err
	}
	err = i.database.Init()
	if err != nil {
		return err
	}
	err = i.database.InitConfig()
	if err != nil {
		return err
	}

	err = i.ClearVersion()
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}
	return nil

}
func (i *Installer) AccessChange() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) StorageChange() error {
	storageDir, err := i.platformClient.InitStorage(App, App)
	if err != nil {
		return err
	}
	err = linux.Chown(storageDir, App)
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) ClearVersion() error {
	return os.RemoveAll(i.currentVersionFile)
}

func (i *Installer) UpdateVersion() error {
	return cp.Copy(i.newVersionFile, i.currentVersionFile)
}

func (i *Installer) UpdateConfigs() error {
	err := linux.CreateUser(App)
	if err != nil {
		return err
	}

	err = i.StorageChange()
	if err != nil {
		return err
	}

	domain, err := i.platformClient.GetAppDomainName(App)
	if err != nil {
		return err
	}

	variables := Variables{
		AppDir:       i.appDir,
		CommonDir:    i.commonDir,
		DataDir:      i.dataDir,
		DatabaseDir:  i.database.DatabaseDir(),
		DatabasePort: 5436,
		Domain:       domain,
	}

	err = config.GenerateWithDelims(
		path.Join(i.appDir, "config"),
		path.Join(i.dataDir, "config"),
		variables,
		"{{{",
		"}}}",
	)
	if err != nil {
		return err
	}

	err = linux.CreateMissingDirs(
		path.Join(i.dataDir, "nginx"),
		path.Join(i.dataDir, "data"),
	)
	if err != nil {
		return err
	}

	err = i.RegisterGoBridge("whatsapp")
	if err != nil {
		return err
	}
	err = i.RegisterGoBridge("slack")
	if err != nil {
		return err
	}
	err = i.RegisterGoBridge("discord")
	if err != nil {
		return err
	}
	err = i.RegisterGoBridge("telegram")
	if err != nil {
		return err
	}
	err = i.RegisterGoBridge("signal")
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}

	return nil

}

func (i *Installer) RegisterGoBridge(bridge string) error {
	return i.executor.Run(
		path.Join(i.appDir, "bin", bridge),
		"-g",
		"-c", path.Join(i.configDir, fmt.Sprint(bridge, ".yaml")),
		"-r", path.Join(i.configDir, fmt.Sprint(bridge, "-registration.yaml")),
	)
}

func (i *Installer) RegisterPythonBridge(bridge string) error {
	return i.executor.Run(
		path.Join(i.appDir, "python/bin/python"),
		"-m", fmt.Sprint("mautrix_", bridge),
		"-g",
		"-c", path.Join(i.configDir, fmt.Sprint(bridge, ".yaml")),
		"-r", path.Join(i.configDir, fmt.Sprint(bridge, "-registration.yaml")),
	)
}

func (i *Installer) FixPermissions() error {
	storageDir, err := i.platformClient.InitStorage(App, App)
	if err != nil {
		return err
	}

	err = linux.Chown(i.dataDir, App)
	if err != nil {
		return err
	}
	err = linux.Chown(i.commonDir, App)
	if err != nil {
		return err
	}

	err = linux.Chown(storageDir, App)
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) BackupPreStop() error {
	return i.PreRefresh()
}

func (i *Installer) RestorePreStart() error {
	return i.PostRefresh()
}

func (i *Installer) RestorePostStart() error {
	return i.Configure()
}

func (i *Installer) SetSyncSecret() error {
	file := path.Join(i.dataDir, "sync.secret")
	_, err := os.Stat(file)
	if os.IsNotExist(err) {
		secret := uuid.New().String()
		err = os.WriteFile(file, []byte(secret), 0644)
		return err
	}
	return nil
}
