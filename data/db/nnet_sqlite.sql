DROP TABLE IF EXISTS Match_First25;
CREATE TABLE Match_First25 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        competitionID BIGINT(20) NOT NULL,
        team1ID BIGINT(20) NOT NULL,
        team2ID BIGINT(20) NOT NULL,
        goals1 INTEGER(3) NOT NULL,
        goals2 INTEGER(3) NOT NULL,
        modifieddate DATETIME NOT NULL DEFAULT '$now'
);

DROP TABLE IF EXISTS Match_First50;
CREATE TABLE Match_First50 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        competitionID BIGINT(20) NOT NULL,
        team1ID BIGINT(20) NOT NULL,
        team2ID BIGINT(20) NOT NULL,
        goals1 INTEGER(3) NOT NULL,
        goals2 INTEGER(3) NOT NULL,
        modifieddate DATETIME NOT NULL DEFAULT '$now'
);

DROP TABLE IF EXISTS Match_First75;
CREATE TABLE Match_First75 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        competitionID BIGINT(20) NOT NULL,
        team1ID BIGINT(20) NOT NULL,
        team2ID BIGINT(20) NOT NULL,
        goals1 INTEGER(3) NOT NULL,
        goals2 INTEGER(3) NOT NULL,
        modifieddate DATETIME NOT NULL DEFAULT '$now'
);

DROP TABLE IF EXISTS Match_Last25;
CREATE TABLE Match_Last25 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        competitionID BIGINT(20) NOT NULL,
        team1ID BIGINT(20) NOT NULL,
        team2ID BIGINT(20) NOT NULL,
        goals1 INTEGER(3) NOT NULL,
        goals2 INTEGER(3) NOT NULL,
        modifieddate DATETIME NOT NULL DEFAULT '$now'
);

DROP TABLE IF EXISTS Match_Last50;
CREATE TABLE Match_Last50 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        competitionID BIGINT(20) NOT NULL,
        team1ID BIGINT(20) NOT NULL,
        team2ID BIGINT(20) NOT NULL,
        goals1 INTEGER(3) NOT NULL,
        goals2 INTEGER(3) NOT NULL,
        modifieddate DATETIME NOT NULL DEFAULT '$now'
);

DROP TABLE IF EXISTS Match_Last75;
CREATE TABLE Match_Last75 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        competitionID BIGINT(20) NOT NULL,
        team1ID BIGINT(20) NOT NULL,
        team2ID BIGINT(20) NOT NULL,
        goals1 INTEGER(3) NOT NULL,
        goals2 INTEGER(3) NOT NULL,
        modifieddate DATETIME NOT NULL DEFAULT '$now'
);

-- Copy last 25 % of matches per competition

INSERT INTO Match_Last25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1 ORDER BY m.id DESC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1)/100;
INSERT INTO Match_Last25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2 ORDER BY m.id DESC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2)/100;
INSERT INTO Match_Last25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3 ORDER BY m.id DESC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3)/100;
INSERT INTO Match_Last25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4 ORDER BY m.id DESC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4)/100;
INSERT INTO Match_Last25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5 ORDER BY m.id DESC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5)/100;
INSERT INTO Match_Last25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6 ORDER BY m.id DESC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6)/100;
INSERT INTO Match_Last25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7 ORDER BY m.id DESC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7)/100;
INSERT INTO Match_Last25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8 ORDER BY m.id DESC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8)/100;

-- Copy last 50 % of matches per competition

INSERT INTO Match_Last50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1 ORDER BY m.id DESC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1)/100;
INSERT INTO Match_Last50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2 ORDER BY m.id DESC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2)/100;
INSERT INTO Match_Last50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3 ORDER BY m.id DESC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3)/100;
INSERT INTO Match_Last50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4 ORDER BY m.id DESC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4)/100;
INSERT INTO Match_Last50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5 ORDER BY m.id DESC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5)/100;
INSERT INTO Match_Last50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6 ORDER BY m.id DESC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6)/100;
INSERT INTO Match_Last50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7 ORDER BY m.id DESC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7)/100;
INSERT INTO Match_Last50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8 ORDER BY m.id DESC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8)/100;

-- Copy last 75 % of matches per competition

INSERT INTO Match_Last75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1 ORDER BY m.id DESC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1)/100;
INSERT INTO Match_Last75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2 ORDER BY m.id DESC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2)/100;
INSERT INTO Match_Last75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3 ORDER BY m.id DESC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3)/100;
INSERT INTO Match_Last75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4 ORDER BY m.id DESC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4)/100;
INSERT INTO Match_Last75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5 ORDER BY m.id DESC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5)/100;
INSERT INTO Match_Last75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6 ORDER BY m.id DESC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6)/100;
INSERT INTO Match_Last75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7 ORDER BY m.id DESC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7)/100;
INSERT INTO Match_Last75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8 ORDER BY m.id DESC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8)/100;

-- Copy first 25 % of matches per competition

INSERT INTO Match_First25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1 ORDER BY m.id ASC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1)/100;
INSERT INTO Match_First25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2 ORDER BY m.id ASC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2)/100;
INSERT INTO Match_First25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3 ORDER BY m.id ASC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3)/100;
INSERT INTO Match_First25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4 ORDER BY m.id ASC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4)/100;
INSERT INTO Match_First25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5 ORDER BY m.id ASC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5)/100;
INSERT INTO Match_First25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6 ORDER BY m.id ASC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6)/100;
INSERT INTO Match_First25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7 ORDER BY m.id ASC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7)/100;
INSERT INTO Match_First25 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8 ORDER BY m.id ASC LIMIT 25*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8)/100;

-- Copy first 50 % of matches per competition

INSERT INTO Match_First50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1 ORDER BY m.id ASC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1)/100;
INSERT INTO Match_First50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2 ORDER BY m.id ASC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2)/100;
INSERT INTO Match_First50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3 ORDER BY m.id ASC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3)/100;
INSERT INTO Match_First50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4 ORDER BY m.id ASC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4)/100;
INSERT INTO Match_First50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5 ORDER BY m.id ASC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5)/100;
INSERT INTO Match_First50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6 ORDER BY m.id ASC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6)/100;
INSERT INTO Match_First50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7 ORDER BY m.id ASC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7)/100;
INSERT INTO Match_First50 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8 ORDER BY m.id ASC LIMIT 50*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8)/100;

-- Copy first 75 % of matches per competition

INSERT INTO Match_First75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1 ORDER BY m.id ASC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 1)/100;
INSERT INTO Match_First75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2 ORDER BY m.id ASC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 2)/100;
INSERT INTO Match_First75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3 ORDER BY m.id ASC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 3)/100;
INSERT INTO Match_First75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4 ORDER BY m.id ASC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 4)/100;
INSERT INTO Match_First75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5 ORDER BY m.id ASC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 5)/100;
INSERT INTO Match_First75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6 ORDER BY m.id ASC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 6)/100;
INSERT INTO Match_First75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7 ORDER BY m.id ASC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 7)/100;
INSERT INTO Match_First75 SELECT m.* FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8 ORDER BY m.id ASC LIMIT 75*(SELECT COUNT(*) FROM Match m LEFT JOIN Competition c ON m.competitionID = c.id WHERE c.id = 8)/100;
