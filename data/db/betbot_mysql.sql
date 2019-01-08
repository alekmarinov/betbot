BEGIN;
CREATE TABLE Provider (
	id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
	title VARCHAR(255) NOT NULL
);
INSERT INTO Provider (title) VALUES ('smarterbetting');
INSERT INTO Provider (title) VALUES ('soccerstand');
INSERT INTO Provider (title) VALUES ('365stats');
INSERT INTO Provider (title) VALUES ('football_data');
CREATE TABLE Location (
	id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
	title VARCHAR(255) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT now()
);
CREATE TABLE Competition (
	id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
	title VARCHAR(255) NOT NULL,
	locationID BIGINT(20) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT now()
);
CREATE TABLE Team (
	id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
	title VARCHAR(255) NOT NULL,
	locationID BIGINT(20) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT now()
);
CREATE TABLE Bookmaker (
	id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
	title VARCHAR(255) NOT NULL,
	website VARCHAR(255) NOT NULL DEFAULT '',
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT now()
);
CREATE TABLE Match (
	id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
	date DATETIME NOT NULL,
	competitionID BIGINT(20) NOT NULL,
	team1ID BIGINT(20) NOT NULL,
	team2ID BIGINT(20) NOT NULL,
	goals1 INTEGER(3) NOT NULL,
	goals2 INTEGER(3) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT now()
);
CREATE TABLE Odds (
	bookmakerID BIGINT(20) NOT NULL,
	matchID BIGINT(20) NOT NULL,
	home FLOAT(20) NOT NULL,
	draw FLOAT(20) NOT NULL,
	away FLOAT(20) NOT NULL,
	providerID BIGINT(20) NOT NULL,
	modifieddate DATETIME NOT NULL DEFAULT now()
);
CREATE INDEX IDX_Odds_1 ON Odds (bookmakerID, matchID);
COMMIT;
