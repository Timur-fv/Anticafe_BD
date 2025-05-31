--
-- PostgreSQL database dump
--

-- Dumped from database version 17.0
-- Dumped by pg_dump version 17.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: Anticafe; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "Anticafe" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';


ALTER DATABASE "Anticafe" OWNER TO postgres;

\connect "Anticafe"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: RestZones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."RestZones" (
    zone_id bigint NOT NULL,
    zone_type character varying(50) NOT NULL,
    capacity smallint NOT NULL,
    description text NOT NULL,
    status character varying(50) DEFAULT 'active'::character varying NOT NULL,
    CONSTRAINT "RestZones_capacity_check" CHECK ((capacity > 0)),
    CONSTRAINT "RestZones_status_check" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'maintenance'::character varying, 'closed'::character varying])::text[]))),
    CONSTRAINT "RestZones_zone_type_check" CHECK (((zone_type)::text = ANY ((ARRAY['relax'::character varying, 'games'::character varying, 'work'::character varying, 'event'::character varying])::text[])))
);


ALTER TABLE public."RestZones" OWNER TO postgres;

--
-- Name: TABLE "RestZones"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."RestZones" IS 'Таблица зон отдыха с типами: relax, games, work, event';


--
-- Name: COLUMN "RestZones".zone_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."RestZones".zone_type IS 'Тип зоны отдыха: relax, games, work или event';


--
-- Name: COLUMN "RestZones".status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."RestZones".status IS 'Текущий статус зоны: active, maintenance или closed';


--
-- Name: Visitors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Visitors" (
    visitor_id bigint NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    phone character varying(15) NOT NULL,
    email character varying(50) NOT NULL,
    entry_time timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    exit_time timestamp(0) without time zone,
    current_zone_id bigint NOT NULL,
    tariff_id bigint NOT NULL,
    CONSTRAINT "Visitors_email_check" CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]+$'::text)),
    CONSTRAINT "Visitors_first_name_check" CHECK ((length((first_name)::text) >= 2)),
    CONSTRAINT "Visitors_last_name_check" CHECK ((length((last_name)::text) >= 2)),
    CONSTRAINT "Visitors_phone_check" CHECK (((phone)::text ~ '^\+?[0-9]{10,15}$'::text))
);


ALTER TABLE public."Visitors" OWNER TO postgres;

--
-- Name: TABLE "Visitors"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."Visitors" IS 'Основная информация о посетителях комплекса';


--
-- Name: COLUMN "Visitors".exit_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."Visitors".exit_time IS 'Время выхода (NULL, если посетитель еще в комплексе)';


--
-- Name: COLUMN "Visitors".current_zone_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."Visitors".current_zone_id IS 'Текущая зона, в которой находится посетитель (FK к RestZones)';


--
-- Name: COLUMN "Visitors".tariff_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."Visitors".tariff_id IS 'Выбранный тариф посетителем (FK к Tariffs)';


--
-- Name: ActiveZoneVisitors; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."ActiveZoneVisitors" AS
 SELECT rz.zone_id,
    rz.zone_type,
    rz.capacity,
    count(v.visitor_id) AS current_visitors_count
   FROM (public."RestZones" rz
     LEFT JOIN public."Visitors" v ON (((rz.zone_id = v.current_zone_id) AND (v.exit_time IS NULL))))
  WHERE ((rz.status)::text = 'active'::text)
  GROUP BY rz.zone_id, rz.zone_type, rz.capacity;


ALTER VIEW public."ActiveZoneVisitors" OWNER TO postgres;

--
-- Name: Activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Activities" (
    activity_id bigint NOT NULL,
    name character varying(50) NOT NULL,
    description text NOT NULL,
    schedule character varying(50) NOT NULL,
    max_participants smallint NOT NULL,
    current_participants smallint NOT NULL,
    staff_id bigint NOT NULL,
    CONSTRAINT "Activities_check" CHECK (((current_participants >= 0) AND (current_participants <= max_participants))),
    CONSTRAINT "Activities_max_participants_check" CHECK ((max_participants > 0))
);


ALTER TABLE public."Activities" OWNER TO postgres;

--
-- Name: TABLE "Activities"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."Activities" IS 'Мероприятия в антикафе';


--
-- Name: Bills; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Bills" (
    bill_id bigint NOT NULL,
    visitor_id bigint NOT NULL,
    tariff_id bigint NOT NULL,
    total_time integer NOT NULL,
    base_cost numeric(10,2) NOT NULL,
    orders_cost numeric(10,2) DEFAULT 0 NOT NULL,
    discount_amount numeric(10,2) DEFAULT 0 NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    payment_method character varying(20) NOT NULL,
    payment_status character varying(50) DEFAULT 'unpaid'::character varying NOT NULL,
    CONSTRAINT "Bills_base_cost_check" CHECK ((base_cost >= (0)::numeric)),
    CONSTRAINT "Bills_discount_amount_check" CHECK ((discount_amount >= (0)::numeric)),
    CONSTRAINT "Bills_orders_cost_check" CHECK ((orders_cost >= (0)::numeric)),
    CONSTRAINT "Bills_payment_method_check" CHECK (((payment_method)::text = ANY ((ARRAY['cash'::character varying, 'card'::character varying, 'online'::character varying, 'voucher'::character varying])::text[]))),
    CONSTRAINT "Bills_payment_status_check" CHECK (((payment_status)::text = ANY ((ARRAY['unpaid'::character varying, 'paid'::character varying, 'partially_paid'::character varying, 'refunded'::character varying])::text[]))),
    CONSTRAINT "Bills_total_amount_check" CHECK ((total_amount >= (0)::numeric)),
    CONSTRAINT "Bills_total_time_check" CHECK ((total_time > 0))
);


ALTER TABLE public."Bills" OWNER TO postgres;

--
-- Name: TABLE "Bills"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."Bills" IS 'Счета для посетителей';


--
-- Name: Orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Orders" (
    order_id bigint NOT NULL,
    visitor_id bigint NOT NULL,
    item_type character varying(50) NOT NULL,
    item_name character varying(50) NOT NULL,
    price numeric(6,2) NOT NULL,
    order_time timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status character varying(50) DEFAULT 'ordered'::character varying NOT NULL,
    CONSTRAINT "Orders_item_type_check" CHECK (((item_type)::text = ANY ((ARRAY['drink'::character varying, 'snack'::character varying, 'dessert'::character varying, 'combo'::character varying])::text[]))),
    CONSTRAINT "Orders_price_check" CHECK ((price >= (0)::numeric)),
    CONSTRAINT "Orders_status_check" CHECK (((status)::text = ANY ((ARRAY['ordered'::character varying, 'preparing'::character varying, 'ready'::character varying, 'delivered'::character varying])::text[])))
);


ALTER TABLE public."Orders" OWNER TO postgres;

--
-- Name: TABLE "Orders"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."Orders" IS 'Заказы в антикафе';


--
-- Name: Participation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Participation" (
    activity_id bigint NOT NULL,
    visitor_id bigint NOT NULL
);


ALTER TABLE public."Participation" OWNER TO postgres;

--
-- Name: TABLE "Participation"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."Participation" IS 'Связь M:N между мероприятиями и посетителями';


--
-- Name: Staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Staff" (
    staff_id bigint NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    "position" character varying(50) NOT NULL,
    phone character varying(15) NOT NULL,
    email character varying(50) NOT NULL,
    hire_date date NOT NULL,
    CONSTRAINT "Staff_email_check" CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]+$'::text)),
    CONSTRAINT "Staff_first_name_check" CHECK ((length((first_name)::text) >= 2)),
    CONSTRAINT "Staff_hire_date_check" CHECK ((hire_date <= CURRENT_DATE)),
    CONSTRAINT "Staff_last_name_check" CHECK ((length((last_name)::text) >= 2)),
    CONSTRAINT "Staff_phone_check" CHECK (((phone)::text ~ '^\+?[0-9]{10,15}$'::text)),
    CONSTRAINT "Staff_position_check" CHECK ((("position")::text = ANY ((ARRAY['manager'::character varying, 'barista'::character varying, 'game_master'::character varying, 'cleaner'::character varying])::text[])))
);


ALTER TABLE public."Staff" OWNER TO postgres;

--
-- Name: TABLE "Staff"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."Staff" IS 'Информация о сотрудниках антикафе';


--
-- Name: COLUMN "Staff"."position"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."Staff"."position" IS 'Должность сотрудника: manager, barista, game_master, cleaner';


--
-- Name: COLUMN "Staff".hire_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."Staff".hire_date IS 'Дата приема на работу (не может быть в будущем)';


--
-- Name: StaffActivitySummary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."StaffActivitySummary" AS
 SELECT s.staff_id,
    s.first_name,
    s.last_name,
    count(a.activity_id) AS activities_count,
    COALESCE(avg(a.current_participants), (0)::numeric) AS avg_participants_per_activity
   FROM (public."Staff" s
     LEFT JOIN public."Activities" a ON ((s.staff_id = a.staff_id)))
  GROUP BY s.staff_id, s.first_name, s.last_name;


ALTER VIEW public."StaffActivitySummary" OWNER TO postgres;

--
-- Name: Tariffs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Tariffs" (
    tariff_id bigint NOT NULL,
    name character varying(50) NOT NULL,
    price_per_hour numeric(10,2) NOT NULL,
    discount numeric(5,2) NOT NULL,
    min_duration smallint NOT NULL,
    max_duration smallint NOT NULL,
    CONSTRAINT "Tariffs_check" CHECK ((max_duration >= min_duration)),
    CONSTRAINT "Tariffs_discount_check" CHECK (((discount >= (0)::numeric) AND (discount <= (30)::numeric))),
    CONSTRAINT "Tariffs_min_duration_check" CHECK ((min_duration >= 0)),
    CONSTRAINT "Tariffs_name_check" CHECK (((name)::text = ANY ((ARRAY['hourly'::character varying, 'daytime'::character varying, 'evening'::character varying, 'weekend'::character varying, 'unlimited'::character varying])::text[]))),
    CONSTRAINT "Tariffs_price_per_hour_check" CHECK ((price_per_hour > (0)::numeric))
);


ALTER TABLE public."Tariffs" OWNER TO postgres;

--
-- Name: TABLE "Tariffs"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."Tariffs" IS 'Тарифные планы: hourly, daytime, evening, weekend, unlimited';


--
-- Name: COLUMN "Tariffs".discount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."Tariffs".discount IS 'Процент скидки (от 0 до 30%)';


--
-- Name: VisitorProfiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VisitorProfiles" (
    profile_id bigint NOT NULL,
    visitor_id bigint NOT NULL,
    loyalty_points integer NOT NULL,
    favorite_zone_type character varying(50),
    membership_level character varying(50) DEFAULT 'regular'::character varying NOT NULL,
    CONSTRAINT "VisitorProfiles_favorite_zone_type_check" CHECK (((favorite_zone_type)::text = ANY ((ARRAY['relax'::character varying, 'games'::character varying, 'work'::character varying])::text[]))),
    CONSTRAINT "VisitorProfiles_loyalty_points_check" CHECK ((loyalty_points >= 0)),
    CONSTRAINT "VisitorProfiles_membership_level_check" CHECK (((membership_level)::text = ANY ((ARRAY['regular'::character varying, 'member'::character varying, 'vip'::character varying])::text[])))
);


ALTER TABLE public."VisitorProfiles" OWNER TO postgres;

--
-- Name: TABLE "VisitorProfiles"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."VisitorProfiles" IS 'Информация о лояльности посетителей';


--
-- Name: COLUMN "VisitorProfiles".favorite_zone_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."VisitorProfiles".favorite_zone_type IS 'Любимый тип зоны: relax, games или work';


--
-- Name: COLUMN "VisitorProfiles".membership_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public."VisitorProfiles".membership_level IS 'Уровень членства: regular, member или vip';


--
-- Name: VisitorTotalSpending; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."VisitorTotalSpending" AS
 SELECT v.visitor_id,
    v.first_name,
    v.last_name,
    COALESCE(sum(b.total_amount), (0)::numeric) AS total_spent,
    count(b.bill_id) AS bills_count
   FROM (public."Visitors" v
     LEFT JOIN public."Bills" b ON (((v.visitor_id = b.visitor_id) AND ((b.payment_status)::text = 'paid'::text))))
  GROUP BY v.visitor_id, v.first_name, v.last_name;


ALTER VIEW public."VisitorTotalSpending" OWNER TO postgres;

--
-- Data for Name: Activities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Activities" (activity_id, name, description, schedule, max_participants, current_participants, staff_id) FROM stdin;
1	Игровой турнир по настолкам	Турнир среди посетителей	Каждую субботу 16:00	20	5	3
2	Мастер-класс по рисованию	Рисуем гуашью и акварелью	Воскресенье 12:00	15	8	1
3	Просмотр фильма	Совместный просмотр комедий	Пятница 18:00	30	10	1
4	Турнир по видеоиграм	PlayStation и Xbox	Среда 17:00	16	6	3
5	Квест-комната	Логические задания и квесты	Каждый день по расписанию	6	4	3
\.


--
-- Data for Name: Bills; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Bills" (bill_id, visitor_id, tariff_id, total_time, base_cost, orders_cost, discount_amount, total_amount, payment_method, payment_status) FROM stdin;
1	1	1	120	10.00	5.00	1.50	13.50	card	paid
2	2	2	180	20.00	3.00	2.00	21.00	cash	paid
3	3	3	60	5.00	0.00	0.00	5.00	online	unpaid
4	4	1	90	7.50	2.50	0.00	10.00	card	paid
5	5	4	240	40.00	10.00	8.00	42.00	cash	paid
6	6	2	120	20.00	5.00	2.00	23.00	online	paid
7	7	3	60	10.00	0.00	1.50	8.50	card	paid
8	8	1	180	15.00	4.00	0.00	19.00	cash	paid
9	9	2	150	18.00	3.00	1.80	19.20	online	unpaid
10	10	5	300	60.00	12.00	15.00	57.00	card	paid
11	11	4	210	35.00	7.00	7.00	35.00	cash	paid
12	12	5	360	72.00	15.00	18.00	69.00	online	paid
13	13	1	90	7.50	2.00	0.00	9.50	card	paid
\.


--
-- Data for Name: Orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Orders" (order_id, visitor_id, item_type, item_name, price, order_time, status) FROM stdin;
1	1	drink	Капучино	3.00	2024-05-31 12:05:00	ordered
2	2	snack	Чипсы	2.00	2024-05-31 12:35:00	preparing
3	3	dessert	Тирамису	5.00	2024-05-31 13:10:00	delivered
4	4	combo	Кофе+пирог	6.50	2024-05-31 14:10:00	ordered
5	5	drink	Латте	3.50	2024-05-31 15:15:00	ready
6	6	snack	Орешки	1.50	2024-05-31 16:20:00	delivered
7	7	dessert	Эклер	4.00	2024-05-31 17:25:00	preparing
8	8	combo	Чай+пирог	6.00	2024-05-31 18:30:00	ready
9	9	drink	Американо	2.50	2024-05-31 19:35:00	delivered
10	10	snack	Крекеры	2.00	2024-05-31 20:40:00	ordered
11	11	dessert	Чизкейк	5.50	2024-05-31 21:45:00	ready
12	12	combo	Сок+печенье	5.00	2024-05-31 22:50:00	delivered
13	13	drink	Эспрессо	2.00	2024-05-31 23:55:00	preparing
\.


--
-- Data for Name: Participation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Participation" (activity_id, visitor_id) FROM stdin;
1	1
2	2
3	3
\.


--
-- Data for Name: RestZones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."RestZones" (zone_id, zone_type, capacity, description, status) FROM stdin;
1	relax	10	Зона отдыха с диванами и музыкой	active
2	games	12	Настольные и видеоигры	active
3	work	8	Рабочая зона с Wi-Fi и розетками	maintenance
4	event	20	Площадка для мероприятий	active
\.


--
-- Data for Name: Staff; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Staff" (staff_id, first_name, last_name, "position", phone, email, hire_date) FROM stdin;
1	Анна	Иванова	manager	+79991234567	anna.ivanova@mail.com	2022-01-10
2	Игорь	Петров	barista	+79991234568	igor.petrov@mail.com	2023-03-15
3	Мария	Кузнецова	game_master	+79991234569	maria.kuznetsova@mail.com	2021-07-20
4	Олег	Сидоров	cleaner	+79991234570	oleg.sidorov@mail.com	2022-11-01
\.


--
-- Data for Name: Tariffs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Tariffs" (tariff_id, name, price_per_hour, discount, min_duration, max_duration) FROM stdin;
1	hourly	5.00	0.00	0	60
2	daytime	20.00	10.00	60	180
3	evening	25.00	15.00	180	240
4	weekend	30.00	20.00	120	300
5	unlimited	40.00	25.00	0	1440
\.


--
-- Data for Name: VisitorProfiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VisitorProfiles" (profile_id, visitor_id, loyalty_points, favorite_zone_type, membership_level) FROM stdin;
1	1	100	relax	vip
2	2	80	games	member
3	3	60	work	regular
\.


--
-- Data for Name: Visitors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Visitors" (visitor_id, first_name, last_name, phone, email, entry_time, exit_time, current_zone_id, tariff_id) FROM stdin;
1	Сергей	Морозов	+79991230001	sergey.morozov@mail.ru	2024-05-31 12:00:00	\N	1	1
2	Ольга	Новикова	+79991230002	olga.novikova@yandex.ru	2024-05-31 12:30:00	\N	2	2
3	Никита	Смирнов	+79991230003	nikita.smirnov@mail.ru	2024-05-31 13:00:00	\N	3	3
4	Елена	Ковалёва	+79991230004	elena.kovaleva@gmail.com	2024-05-31 14:00:00	\N	1	1
5	Дмитрий	Васильев	+79991230005	dmitriy.vasiliev@mail.ru	2024-05-31 15:00:00	\N	2	4
6	Анна	Лебедева	+79991230006	anna.lebedeva@yandex.ru	2024-05-31 16:00:00	\N	3	2
7	Игорь	Титов	+79991230007	igor.titov@mail.ru	2024-05-31 17:00:00	\N	4	3
8	Марина	Соколова	+79991230008	marina.sokolova@gmail.com	2024-05-31 18:00:00	\N	1	1
9	Алексей	Новиков	+79991230009	aleksey.novikov@mail.ru	2024-05-31 19:00:00	\N	2	2
10	Виктория	Морозова	+79991230010	victoria.morozova@yandex.ru	2024-05-31 20:00:00	\N	3	5
11	Павел	Орлов	+79991230011	pavel.orlov@mail.ru	2024-05-31 21:00:00	\N	4	4
12	Юлия	Кузьмина	+79991230012	yulia.kuzmina@gmail.com	2024-05-31 22:00:00	\N	1	5
13	Константин	Григорьев	+79991230013	konstantin.grigoriev@mail.ru	2024-05-31 23:00:00	\N	2	1
\.


--
-- Name: Activities Activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Activities"
    ADD CONSTRAINT "Activities_pkey" PRIMARY KEY (activity_id);


--
-- Name: Bills Bills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Bills"
    ADD CONSTRAINT "Bills_pkey" PRIMARY KEY (bill_id);


--
-- Name: Orders Orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Orders"
    ADD CONSTRAINT "Orders_pkey" PRIMARY KEY (order_id);


--
-- Name: Participation Participation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Participation"
    ADD CONSTRAINT "Participation_pkey" PRIMARY KEY (activity_id, visitor_id);


--
-- Name: RestZones RestZones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RestZones"
    ADD CONSTRAINT "RestZones_pkey" PRIMARY KEY (zone_id);


--
-- Name: Staff Staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Staff"
    ADD CONSTRAINT "Staff_pkey" PRIMARY KEY (staff_id);


--
-- Name: Tariffs Tariffs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Tariffs"
    ADD CONSTRAINT "Tariffs_pkey" PRIMARY KEY (tariff_id);


--
-- Name: VisitorProfiles VisitorProfiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VisitorProfiles"
    ADD CONSTRAINT "VisitorProfiles_pkey" PRIMARY KEY (profile_id);


--
-- Name: VisitorProfiles VisitorProfiles_visitor_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VisitorProfiles"
    ADD CONSTRAINT "VisitorProfiles_visitor_id_key" UNIQUE (visitor_id);


--
-- Name: Visitors Visitors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Visitors"
    ADD CONSTRAINT "Visitors_pkey" PRIMARY KEY (visitor_id);


--
-- Name: idx_activities_staff; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activities_staff ON public."Activities" USING btree (staff_id);


--
-- Name: idx_bills_visitor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bills_visitor ON public."Bills" USING btree (visitor_id);


--
-- Name: idx_participation_activity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_participation_activity ON public."Participation" USING btree (activity_id);


--
-- Name: idx_participation_visitor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_participation_visitor ON public."Participation" USING btree (visitor_id);


--
-- Name: idx_staff_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_phone ON public."Staff" USING btree (phone);


--
-- Name: idx_visitorprofiles_visitor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_visitorprofiles_visitor ON public."VisitorProfiles" USING btree (visitor_id);


--
-- Name: idx_visitors_tariff; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_visitors_tariff ON public."Visitors" USING btree (tariff_id);


--
-- Name: idx_visitors_zone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_visitors_zone ON public."Visitors" USING btree (current_zone_id);


--
-- Name: Activities activities_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Activities"
    ADD CONSTRAINT activities_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public."Staff"(staff_id);


--
-- Name: Bills bills_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Bills"
    ADD CONSTRAINT bills_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public."Visitors"(visitor_id);


--
-- Name: Orders orders_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Orders"
    ADD CONSTRAINT orders_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public."Visitors"(visitor_id);


--
-- Name: Participation participation_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Participation"
    ADD CONSTRAINT participation_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public."Activities"(activity_id);


--
-- Name: Participation participation_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Participation"
    ADD CONSTRAINT participation_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public."Visitors"(visitor_id);


--
-- Name: VisitorProfiles visitorprofiles_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VisitorProfiles"
    ADD CONSTRAINT visitorprofiles_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public."Visitors"(visitor_id);


--
-- Name: Visitors visitors_current_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Visitors"
    ADD CONSTRAINT visitors_current_zone_id_fkey FOREIGN KEY (current_zone_id) REFERENCES public."RestZones"(zone_id);


--
-- Name: Visitors visitors_tariff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Visitors"
    ADD CONSTRAINT visitors_tariff_id_fkey FOREIGN KEY (tariff_id) REFERENCES public."Tariffs"(tariff_id);


--
-- PostgreSQL database dump complete
--

