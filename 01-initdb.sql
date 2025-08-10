--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.
--

-- This script will be automatically executed by PostgreSQL when the container starts
-- It initializes the Guacamole database schema

-- Create the guacamole_entity table
CREATE TABLE guacamole_entity (

  entity_id     SERIAL       NOT NULL,
  name          VARCHAR(128) NOT NULL,
  type          VARCHAR(16)  NOT NULL,

  PRIMARY KEY (entity_id),
  UNIQUE (type, name)

);

-- Create the guacamole_user table
CREATE TABLE guacamole_user (

  user_id       INTEGER      NOT NULL,
  username      VARCHAR(128) NOT NULL,
  password_hash BYTEA        NOT NULL,
  password_salt BYTEA,
  password_date DATE,
  disabled      BOOLEAN      NOT NULL DEFAULT FALSE,
  expired       BOOLEAN      NOT NULL DEFAULT FALSE,
  access_window_start    TIME,
  access_window_end      TIME,
  valid_from    DATE,
  valid_until   DATE,
  timezone      VARCHAR(64),
  full_name     VARCHAR(256),
  email_address VARCHAR(256),
  organization  VARCHAR(256),
  organizational_role VARCHAR(256),

  PRIMARY KEY (user_id),

  CONSTRAINT guacamole_user_single_entity
    FOREIGN KEY (user_id) REFERENCES guacamole_entity (entity_id)
    ON DELETE CASCADE

);

-- Create index on username for performance
CREATE UNIQUE INDEX ON guacamole_user(username);

-- Create the guacamole_user_group table
CREATE TABLE guacamole_user_group (

  user_group_id INTEGER      NOT NULL,
  group_name    VARCHAR(128) NOT NULL,
  disabled      BOOLEAN      NOT NULL DEFAULT FALSE,

  PRIMARY KEY (user_group_id),

  CONSTRAINT guacamole_user_group_single_entity
    FOREIGN KEY (user_group_id) REFERENCES guacamole_entity (entity_id)
    ON DELETE CASCADE

);

-- Create index on group name for performance
CREATE UNIQUE INDEX ON guacamole_user_group(group_name);

-- Create the guacamole_user_group_member table
CREATE TABLE guacamole_user_group_member (

  user_group_id    INTEGER NOT NULL,
  member_entity_id INTEGER NOT NULL,

  PRIMARY KEY (user_group_id, member_entity_id),

  CONSTRAINT guacamole_user_group_member_parent
    FOREIGN KEY (user_group_id) REFERENCES guacamole_user_group (user_group_id) ON DELETE CASCADE,

  CONSTRAINT guacamole_user_group_member_member
    FOREIGN KEY (member_entity_id) REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE

);

-- Create the guacamole_connection_group table
CREATE TABLE guacamole_connection_group (

  connection_group_id   INTEGER       NOT NULL,
  parent_id             INTEGER,
  connection_group_name VARCHAR(128)  NOT NULL,
  type                  VARCHAR(32)   NOT NULL
                        DEFAULT 'ORGANIZATIONAL',
  max_connections       INTEGER,
  max_connections_per_user INTEGER,
  enable_session_affinity BOOLEAN NOT NULL DEFAULT FALSE,

  PRIMARY KEY (connection_group_id),

  CONSTRAINT guacamole_connection_group_single_entity
    FOREIGN KEY (connection_group_id) REFERENCES guacamole_entity (entity_id)
    ON DELETE CASCADE,

  CONSTRAINT guacamole_connection_group_parent
    FOREIGN KEY (parent_id) REFERENCES guacamole_connection_group (connection_group_id)
    ON DELETE CASCADE

);

-- Create index on parent_id for performance
CREATE INDEX ON guacamole_connection_group(parent_id);

-- Create the guacamole_connection table
CREATE TABLE guacamole_connection (

  connection_id       INTEGER       NOT NULL,
  connection_name     VARCHAR(128)  NOT NULL,
  parent_id           INTEGER,
  protocol            VARCHAR(32)   NOT NULL,
  max_connections     INTEGER,
  max_connections_per_user INTEGER,
  connection_weight   INTEGER,
  failover_only       BOOLEAN       NOT NULL DEFAULT FALSE,
  proxy_hostname      VARCHAR(512),
  proxy_port          INTEGER,
  proxy_encryption_method VARCHAR(4),

  PRIMARY KEY (connection_id),

  CONSTRAINT guacamole_connection_single_entity
    FOREIGN KEY (connection_id) REFERENCES guacamole_entity (entity_id)
    ON DELETE CASCADE,

  CONSTRAINT guacamole_connection_parent
    FOREIGN KEY (parent_id) REFERENCES guacamole_connection_group (connection_group_id)
    ON DELETE CASCADE

);

-- Create index on parent_id for performance
CREATE INDEX ON guacamole_connection(parent_id);

-- Create the guacamole_connection_parameter table
CREATE TABLE guacamole_connection_parameter (

  connection_id   INTEGER       NOT NULL,
  parameter_name  VARCHAR(128)  NOT NULL,
  parameter_value VARCHAR(4096) NOT NULL,

  PRIMARY KEY (connection_id, parameter_name),

  CONSTRAINT guacamole_connection_parameter_connection
    FOREIGN KEY (connection_id) REFERENCES guacamole_connection (connection_id) ON DELETE CASCADE

);

-- Create index on connection_id for performance
CREATE INDEX ON guacamole_connection_parameter(connection_id);

-- Create the guacamole_connection_permission table
CREATE TABLE guacamole_connection_permission (

  entity_id     INTEGER NOT NULL,
  connection_id INTEGER NOT NULL,
  permission    VARCHAR(10) NOT NULL,

  PRIMARY KEY (entity_id, connection_id, permission),

  CONSTRAINT guacamole_connection_permission_entity
    FOREIGN KEY (entity_id) REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE,

  CONSTRAINT guacamole_connection_permission_connection
    FOREIGN KEY (connection_id) REFERENCES guacamole_connection (connection_id) ON DELETE CASCADE

);

-- Create index on entity_id for performance
CREATE INDEX ON guacamole_connection_permission(entity_id);

-- Create the guacamole_connection_group_permission table
CREATE TABLE guacamole_connection_group_permission (

  entity_id           INTEGER NOT NULL,
  connection_group_id INTEGER NOT NULL,
  permission          VARCHAR(10) NOT NULL,

  PRIMARY KEY (entity_id, connection_group_id, permission),

  CONSTRAINT guacamole_connection_group_permission_entity
    FOREIGN KEY (entity_id) REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE,

  CONSTRAINT guacamole_connection_group_permission_connection_group
    FOREIGN KEY (connection_group_id) REFERENCES guacamole_connection_group (connection_group_id) ON DELETE CASCADE

);

-- Create index on entity_id for performance
CREATE INDEX ON guacamole_connection_group_permission(entity_id);

-- Create the guacamole_system_permission table
CREATE TABLE guacamole_system_permission (

  entity_id  INTEGER     NOT NULL,
  permission VARCHAR(32) NOT NULL,

  PRIMARY KEY (entity_id, permission),

  CONSTRAINT guacamole_system_permission_entity
    FOREIGN KEY (entity_id) REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE

);

-- Create the guacamole_user_permission table
CREATE TABLE guacamole_user_permission (

  entity_id         INTEGER NOT NULL,
  affected_user_id  INTEGER NOT NULL,
  permission        VARCHAR(10) NOT NULL,

  PRIMARY KEY (entity_id, affected_user_id, permission),

  CONSTRAINT guacamole_user_permission_entity
    FOREIGN KEY (entity_id) REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE,

  CONSTRAINT guacamole_user_permission_affected_user
    FOREIGN KEY (affected_user_id) REFERENCES guacamole_user (user_id) ON DELETE CASCADE

);

-- Create index on entity_id for performance
CREATE INDEX ON guacamole_user_permission(entity_id);

-- Create the guacamole_user_group_permission table
CREATE TABLE guacamole_user_group_permission (

  entity_id              INTEGER NOT NULL,
  affected_user_group_id INTEGER NOT NULL,
  permission             VARCHAR(10) NOT NULL,

  PRIMARY KEY (entity_id, affected_user_group_id, permission),

  CONSTRAINT guacamole_user_group_permission_entity
    FOREIGN KEY (entity_id) REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE,

  CONSTRAINT guacamole_user_group_permission_affected_user_group
    FOREIGN KEY (affected_user_group_id) REFERENCES guacamole_user_group (user_group_id) ON DELETE CASCADE

);

-- Create index on entity_id for performance
CREATE INDEX ON guacamole_user_group_permission(entity_id);

-- Create the guacamole_connection_history table
CREATE TABLE guacamole_connection_history (

  history_id           SERIAL       NOT NULL,
  user_id              INTEGER      DEFAULT NULL,
  username             VARCHAR(128) NOT NULL,
  remote_host          VARCHAR(256) DEFAULT NULL,
  connection_id        INTEGER      DEFAULT NULL,
  connection_name      VARCHAR(128) NOT NULL,
  sharing_profile_id   INTEGER      DEFAULT NULL,
  sharing_profile_name VARCHAR(128) DEFAULT NULL,
  start_date           TIMESTAMPTZ  NOT NULL,
  end_date             TIMESTAMPTZ  DEFAULT NULL,

  PRIMARY KEY (history_id),

  CONSTRAINT guacamole_connection_history_user
    FOREIGN KEY (user_id) REFERENCES guacamole_user (user_id) ON DELETE SET NULL,

  CONSTRAINT guacamole_connection_history_connection
    FOREIGN KEY (connection_id) REFERENCES guacamole_connection (connection_id) ON DELETE SET NULL

);

-- Create indexes on connection_history for performance
CREATE INDEX ON guacamole_connection_history(user_id);
CREATE INDEX ON guacamole_connection_history(connection_id);
CREATE INDEX ON guacamole_connection_history(start_date);
CREATE INDEX ON guacamole_connection_history(end_date);

-- Create the guacamole_user_password_history table
CREATE TABLE guacamole_user_password_history (

  password_history_id SERIAL  NOT NULL,
  user_id             INTEGER NOT NULL,
  password_hash       BYTEA   NOT NULL,
  password_salt       BYTEA,
  password_date       TIMESTAMPTZ NOT NULL,

  PRIMARY KEY (password_history_id),

  CONSTRAINT guacamole_user_password_history_user
    FOREIGN KEY (user_id) REFERENCES guacamole_user (user_id) ON DELETE CASCADE

);

-- Create index on user_id for performance
CREATE INDEX ON guacamole_user_password_history(user_id);

-- Insert default admin user
INSERT INTO guacamole_entity (name, type) VALUES ('guacadmin', 'USER');
INSERT INTO guacamole_user (user_id, username, password_hash, password_salt, password_date)
SELECT 
    entity_id,
    'guacadmin',
    decode('CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960', 'hex'),
    decode('FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264', 'hex'),
    CURRENT_DATE
FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER';

-- Grant admin permissions to default user
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission
FROM (
    SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'
) AS admin_user
CROSS JOIN (
    VALUES ('CREATE_CONNECTION'),
           ('CREATE_CONNECTION_GROUP'),
           ('CREATE_SHARING_PROFILE'),
           ('CREATE_USER'),
           ('CREATE_USER_GROUP'),
           ('ADMINISTER')
) AS permissions (permission);

-- Grant user permissions to admin user
INSERT INTO guacamole_user_permission (entity_id, affected_user_id, permission)
SELECT entity_id, entity_id, permission
FROM (
    SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'
) AS admin_user
CROSS JOIN (
    VALUES ('READ'),
           ('UPDATE'),
           ('DELETE')
) AS permissions (permission);
