-- USER
-- Таблицы InnoDB в MySQL снабжены обработчиком таблиц, обеспечивающим безопасные 
-- транзакции (уровня ACID) с возможностями фиксации транзакции, 
-- отката и восстановления после сбоя. 
-- Для таблиц InnoDB осуществляется блокировка на уровне строки, 
-- а также используется метод чтения без блокировок 
-- в команде SELECT (наподобие применяющегося в Oracle). 
-- Перечисленные функции позволяют улучшить взаимную совместимость и 
-- повысить производительность в многопользовательском режиме. 
-- В InnoDB нет необходимости в расширении блокировки, 
-- так как блоки строк в InnoDB занимают очень мало места. 
-- Для таблиц InnoDB поддерживаются ограничивающие условия FOREIGN KEY.

-- year Диапазон значений: 1901 — 2155
drop table if exists user;

create table if not exists user (
   id  int(10) NOT NULL AUTO_INCREMENT,
   name  varchar(255) NULL,
   login  varchar(255) NOT NULL,
   password  varchar(255) NOT NULL,
  PRIMARY KEY ( id ),
  UNIQUE KEY  login  ( login )
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ALBUM
drop table if exists album;

create table if not exists album (
   id  int(10) NOT NULL AUTO_INCREMENT,
   user_id  int(10) NOT NULL,
   album_name  varchar(255) NOT NULL,
   year  year(4) NOT NULL,
   band_name  varchar(255) NOT NULL,
  PRIMARY KEY ( id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CREATE INDEX - данный запрос используется 
-- для создания индексов в таблице.
-- Индексы позволяют быстрее находить нужные данные, 
-- без чтения всей таблицы данных.
-- Пользователь не может увидеть индексы, 
-- они просто используются для ускорения поиска/запроса.
-- После создания индекса на колонку, 
-- MySQL сохранит все ее значения в отсортированном виде:
CREATE INDEX album_user_id_id ON album (user_id ,  id );
-- Создали идекс = отсортированному значению user_id + id(соответствующий user_id)

-- TRACK
drop table if exists track;

create table if not exists track (
   id  int(10) NOT NULL AUTO_INCREMENT,
   album_id  int(10) NOT NULL,
   name  varchar(255) NOT NULL,
   format  varchar(5) NULL,
   `file` varchar(255) NULL,
   `image_http`  varchar(255) NULL,
  PRIMARY KEY ( id )
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE INDEX  track_album_id_id  ON  track  ( album_id ,  id );
-- Создали идекс = отсортированному значению album_id + id(соответствующий album_id)

