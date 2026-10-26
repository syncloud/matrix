package installer

import (
	"fmt"
	"os"
	"path"

	"github.com/syncloud/golib/linux"
	"go.uber.org/zap"
)

const dendriteDatabase = "matrix"

var dendriteExports = []DendriteExport{
	{"accounts.jsonl", `SELECT json_build_object('localpart', localpart, 'server_name', server_name, 'appservice_id', appservice_id, 'deactivated', coalesce(is_deactivated, false), 'account_type', account_type) FROM userapi_accounts ORDER BY created_ts`},
	{"profiles.jsonl", `SELECT json_build_object('localpart', localpart, 'server_name', server_name, 'display_name', display_name, 'avatar_url', avatar_url) FROM userapi_profiles`},
	{"account_data.jsonl", `SELECT json_build_object('localpart', localpart, 'server_name', server_name, 'room_id', room_id, 'type', type, 'content', content) FROM userapi_account_datas`},
	{"devices.jsonl", `SELECT json_build_object('localpart', localpart, 'server_name', server_name, 'device_id', device_id, 'access_token', access_token, 'display_name', display_name, 'ip', ip) FROM userapi_devices`},
	{"device_keys.jsonl", `SELECT json_build_object('user_id', user_id, 'device_id', device_id, 'key_json', key_json) FROM keyserver_device_keys`},
	{"cross_signing_keys.jsonl", `SELECT json_build_object('user_id', user_id, 'key_type', key_type, 'key_data', key_data) FROM keyserver_cross_signing_keys`},
	{"cross_signing_sigs.jsonl", `SELECT json_build_object('origin_user_id', origin_user_id, 'origin_key_id', origin_key_id, 'target_user_id', target_user_id, 'target_key_id', target_key_id, 'signature', signature) FROM keyserver_cross_signing_sigs`},
	{"key_backup_versions.jsonl", `SELECT json_build_object('user_id', user_id, 'version', version::text, 'algorithm', algorithm, 'auth_data', auth_data) FROM userapi_key_backup_versions WHERE deleted = 0`},
	{"key_backups.jsonl", `SELECT json_build_object('user_id', user_id, 'room_id', room_id, 'session_id', session_id, 'version', version, 'first_message_index', first_message_index, 'forwarded_count', forwarded_count, 'is_verified', is_verified, 'session_data', session_data) FROM userapi_key_backups`},
	{"rooms.jsonl", `SELECT json_build_object('room_id', r.room_id, 'room_version', r.room_version, 'latest_event_ids', (SELECT coalesce(json_agg(e.event_id), '[]'::json) FROM roomserver_events e WHERE e.event_nid = ANY(r.latest_event_nids))) FROM roomserver_rooms r`},
	{"events.jsonl", `SELECT json_build_object('room_id', r.room_id, 'event_id', e.event_id, 'json', j.event_json, 'timeline', o.id IS NOT NULL, 'rejected', e.is_rejected) FROM roomserver_events e JOIN roomserver_rooms r ON r.room_nid = e.room_nid JOIN roomserver_event_json j ON j.event_nid = e.event_nid LEFT JOIN syncapi_output_room_events o ON o.event_id = e.event_id ORDER BY r.room_id, o.id IS NOT NULL, e.depth, o.id, e.event_nid`},
	{"state.jsonl", `SELECT json_build_object('room_id', room_id, 'event_id', event_id) FROM syncapi_current_room_state`},
	{"aliases.jsonl", `SELECT json_build_object('alias', alias, 'room_id', room_id, 'creator_id', creator_id) FROM roomserver_room_aliases`},
	{"published.jsonl", `SELECT json_build_object('room_id', room_id) FROM roomserver_published WHERE published`},
	{"media.jsonl", `SELECT json_build_object('media_id', media_id, 'media_origin', media_origin, 'content_type', content_type, 'upload_name', upload_name, 'base64hash', base64hash, 'user_id', user_id) FROM mediaapi_media_repository`},
}

type Dendrite struct {
	appDir    string
	dataDir   string
	configDir string
	database  *Database
	executor  *Executor
	logger    *zap.Logger
}

func NewDendrite(appDir, dataDir, configDir string, database *Database, executor *Executor, logger *zap.Logger) *Dendrite {
	return &Dendrite{
		appDir:    appDir,
		dataDir:   dataDir,
		configDir: configDir,
		database:  database,
		executor:  executor,
		logger:    logger,
	}
}

func (d *Dendrite) Migrate(storageDir string) error {
	if !d.exists() {
		d.logger.Info("no dendrite database to migrate")
		return nil
	}

	exportDir := path.Join(d.dataDir, "dendrite-export")
	tuwunelDir := path.Join(d.dataDir, "tuwunel")
	d.logger.Info("migrating dendrite to tuwunel", zap.String("export", exportDir))

	err := os.RemoveAll(exportDir)
	if err != nil {
		return err
	}
	err = os.RemoveAll(tuwunelDir)
	if err != nil {
		return err
	}
	err = linux.CreateMissingDirs(exportDir, path.Join(exportDir, "appservices"))
	if err != nil {
		return err
	}
	err = linux.Chown(exportDir, App)
	if err != nil {
		return err
	}

	for _, export := range dendriteExports {
		err = d.database.Export(dendriteDatabase, path.Join(exportDir, export.File), export.Query)
		if err != nil {
			return fmt.Errorf("export %s: %w", export.File, err)
		}
	}

	err = d.executor.Run(
		path.Join(d.appDir, "bin", "tuwunel"),
		"--config", path.Join(d.configDir, "tuwunel.toml"),
		"--option", "listening=false",
		"--option", "db_write_buffer_capacity_mb=256",
		"--option", fmt.Sprintf("appservice_dir=%q", path.Join(exportDir, "appservices")),
		"--execute", fmt.Sprintf("server import-dendrite %s --signing-key %s --media-path %s",
			exportDir,
			path.Join(d.dataDir, "private_key.pem"),
			path.Join(storageDir, "media"),
		),
		"--execute", "server shutdown",
	)
	if err != nil {
		return fmt.Errorf("tuwunel import: %w", err)
	}

	summary, err := os.ReadFile(path.Join(exportDir, "imported"))
	if err != nil {
		return fmt.Errorf("tuwunel import did not complete: %w", err)
	}
	d.logger.Info("dendrite imported", zap.String("summary", string(summary)))

	err = d.database.Drop(dendriteDatabase)
	if err != nil {
		return err
	}
	err = d.database.Drop("sync")
	if err != nil {
		return err
	}
	return os.RemoveAll(exportDir)
}

func (d *Dendrite) exists() bool {
	return d.database.Execute(dendriteDatabase, "SELECT 1 FROM roomserver_rooms LIMIT 1") == nil
}
