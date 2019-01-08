BEGIN;
CREATE TABLE Provider (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	title VARCHAR(255) NOT NULL
);
INSERT INTO Provider (title) VALUES ('smarterbetting');
INSERT INTO Provider (title) VALUES ('soccerstand');
INSERT INTO Provider (title) VALUES ('365stats');
INSERT INTO Provider (title) VALUES ('football_data');
CREATE TABLE Location (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	title VARCHAR(255) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT (datetime(current_timestamp, 'localtime'))
);
CREATE TABLE Competition (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	title VARCHAR(255) NOT NULL,
	locationID BIGINT(20) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT (datetime(current_timestamp, 'localtime'))
);
CREATE TABLE Team (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	title VARCHAR(255) NOT NULL,
	locationID BIGINT(20) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT (datetime(current_timestamp, 'localtime'))
);
CREATE TABLE Bookmaker (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	title VARCHAR(255) NOT NULL,
	website VARCHAR(255) NOT NULL DEFAULT '',
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT (datetime(current_timestamp, 'localtime'))
);
CREATE TABLE Match (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	date DATETIME NOT NULL,
	competitionID BIGINT(20) NOT NULL,
	team1ID BIGINT(20) NOT NULL,
	team2ID BIGINT(20) NOT NULL,
	goals1 INTEGER(3) NOT NULL,
	goals2 INTEGER(3) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT (datetime(current_timestamp, 'localtime'))
);
CREATE TABLE Odds (
	bookmakerID BIGINT(20) NOT NULL,
	matchID BIGINT(20) NOT NULL,
	home FLOAT(20) NOT NULL,
	draw FLOAT(20) NOT NULL,
	away FLOAT(20) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT (datetime(current_timestamp, 'localtime'))
);
CREATE INDEX IDX_Odds_1 ON Odds (bookmakerID, matchID);
COMMIT;
