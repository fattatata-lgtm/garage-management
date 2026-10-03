-- =============================================================================
-- Garage Management - File Database (PostgreSQL 14+)
-- Berisi: struktur semua tabel + data awal (akun demo, kategori, sparepart, dll)
--
-- Cara impor (database harus sudah dibuat & kosong):
--   psql -U bengkel_user -d bengkel_db -f database/garage_management.sql
--
-- Akun demo:   admin / admin123   |   staff / staff123   |   teknisi1 / teknisi123
-- PENTING: ganti password akun demo setelah login pertama di server produksi.
--
-- Struktur ini setara dengan seluruh migrasi Prisma di backend/prisma/migrations
-- (sampai 20261002120000_printer_connection).
-- =============================================================================

--
-- PostgreSQL database dump
--


-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: DiscountScope; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DiscountScope" AS ENUM (
    'SEMUA',
    'SERVICE',
    'SPAREPART'
);


--
-- Name: DiscountType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DiscountType" AS ENUM (
    'PERCENTAGE',
    'NOMINAL'
);


--
-- Name: Role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Role" AS ENUM (
    'ADMIN',
    'STAFF',
    'TEKNISI'
);


--
-- Name: ServiceStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ServiceStatus" AS ENUM (
    'DITERIMA',
    'DIKERJAKAN',
    'SELESAI',
    'MENUNGGU_PEMBAYARAN'
);


--
-- Name: StatusAktif; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."StatusAktif" AS ENUM (
    'AKTIF',
    'NONAKTIF'
);


--
-- Name: StockDirection; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."StockDirection" AS ENUM (
    'MASUK',
    'KELUAR'
);


--
-- Name: StockSource; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."StockSource" AS ENUM (
    'MANUAL',
    'SERVICE',
    'PENJUALAN'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Category" (
    id integer NOT NULL,
    name text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: Category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Category_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Category_id_seq" OWNED BY public."Category".id;


--
-- Name: Customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Customer" (
    id integer NOT NULL,
    name text NOT NULL,
    phone text NOT NULL,
    email text,
    address text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: Customer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Customer_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Customer_id_seq" OWNED BY public."Customer".id;


--
-- Name: Discount; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Discount" (
    id integer NOT NULL,
    name text NOT NULL,
    code text,
    type public."DiscountType" NOT NULL,
    value numeric(14,2) NOT NULL,
    status public."StatusAktif" DEFAULT 'AKTIF'::public."StatusAktif" NOT NULL,
    scope public."DiscountScope" DEFAULT 'SEMUA'::public."DiscountScope" NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Discount_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Discount_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Discount_id_seq" OWNED BY public."Discount".id;


--
-- Name: SalesItem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SalesItem" (
    id integer NOT NULL,
    "salesId" integer NOT NULL,
    "sparepartId" integer NOT NULL,
    qty integer NOT NULL,
    price numeric(14,2) NOT NULL
);


--
-- Name: SalesItem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."SalesItem_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: SalesItem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."SalesItem_id_seq" OWNED BY public."SalesItem".id;


--
-- Name: SalesTransaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SalesTransaction" (
    id integer NOT NULL,
    "invoiceNo" text NOT NULL,
    "customerId" integer,
    "walkInName" text,
    date timestamp(3) without time zone NOT NULL,
    "discountId" integer,
    subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    "discountAmount" numeric(14,2) DEFAULT 0 NOT NULL,
    "taxAmount" numeric(14,2) DEFAULT 0 NOT NULL,
    total numeric(14,2) DEFAULT 0 NOT NULL,
    paid numeric(14,2) DEFAULT 0 NOT NULL,
    change numeric(14,2) DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: SalesTransaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."SalesTransaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: SalesTransaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."SalesTransaction_id_seq" OWNED BY public."SalesTransaction".id;


--
-- Name: ServiceDetail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ServiceDetail" (
    id integer NOT NULL,
    "serviceId" integer NOT NULL,
    name text NOT NULL,
    description text,
    cost numeric(14,2) NOT NULL
);


--
-- Name: ServiceDetail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ServiceDetail_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ServiceDetail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ServiceDetail_id_seq" OWNED BY public."ServiceDetail".id;


--
-- Name: ServiceLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ServiceLog" (
    id integer NOT NULL,
    "serviceId" integer NOT NULL,
    status public."ServiceStatus",
    title text NOT NULL,
    note text,
    actor text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ServiceLog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ServiceLog_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ServiceLog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ServiceLog_id_seq" OWNED BY public."ServiceLog".id;


--
-- Name: ServiceSparepart; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ServiceSparepart" (
    id integer NOT NULL,
    "serviceId" integer NOT NULL,
    "sparepartId" integer NOT NULL,
    qty integer NOT NULL,
    price numeric(14,2) NOT NULL
);


--
-- Name: ServiceSparepart_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ServiceSparepart_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ServiceSparepart_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ServiceSparepart_id_seq" OWNED BY public."ServiceSparepart".id;


--
-- Name: ServiceTransaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ServiceTransaction" (
    id integer NOT NULL,
    "invoiceNo" text NOT NULL,
    "vehicleId" integer NOT NULL,
    "technicianId" integer NOT NULL,
    date timestamp(3) without time zone NOT NULL,
    km integer,
    complaint text,
    "internalNote" text,
    status public."ServiceStatus" DEFAULT 'DITERIMA'::public."ServiceStatus" NOT NULL,
    "discountId" integer,
    "nextServiceRecommendation" text,
    "nextServiceDate" timestamp(3) without time zone,
    subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    "discountAmount" numeric(14,2) DEFAULT 0 NOT NULL,
    "taxAmount" numeric(14,2) DEFAULT 0 NOT NULL,
    total numeric(14,2) DEFAULT 0 NOT NULL,
    paid numeric(14,2) DEFAULT 0 NOT NULL,
    change numeric(14,2) DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: ServiceTransaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ServiceTransaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ServiceTransaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ServiceTransaction_id_seq" OWNED BY public."ServiceTransaction".id;


--
-- Name: ServiceType; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ServiceType" (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    "estimatedCost" numeric(14,2) NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ServiceType_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ServiceType_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ServiceType_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ServiceType_id_seq" OWNED BY public."ServiceType".id;


--
-- Name: Settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Settings" (
    id integer DEFAULT 1 NOT NULL,
    "businessName" text DEFAULT 'Self Automotive'::text NOT NULL,
    address text,
    phone text,
    "logoUrl" text,
    "printerType" text,
    "printBridgeHost" text,
    "printBridgePort" integer,
    "taxService" numeric(5,2) DEFAULT 10 NOT NULL,
    "taxSales" numeric(5,2) DEFAULT 10 NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "printerConnection" text DEFAULT 'BROWSER'::text NOT NULL,
    "printerName" text
);


--
-- Name: Sparepart; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Sparepart" (
    id integer NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    "categoryId" integer NOT NULL,
    "buyPrice" numeric(14,2) NOT NULL,
    "sellPrice" numeric(14,2) NOT NULL,
    stock integer DEFAULT 0 NOT NULL,
    "lowStockThreshold" integer DEFAULT 5 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: Sparepart_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Sparepart_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Sparepart_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Sparepart_id_seq" OWNED BY public."Sparepart".id;


--
-- Name: StockHistory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."StockHistory" (
    id integer NOT NULL,
    "sparepartId" integer NOT NULL,
    direction public."StockDirection" NOT NULL,
    source public."StockSource" DEFAULT 'MANUAL'::public."StockSource" NOT NULL,
    quantity integer NOT NULL,
    note text,
    "refInvoice" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: StockHistory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."StockHistory_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: StockHistory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."StockHistory_id_seq" OWNED BY public."StockHistory".id;


--
-- Name: Technician; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Technician" (
    id integer NOT NULL,
    name text NOT NULL,
    skill text,
    status public."StatusAktif" DEFAULT 'AKTIF'::public."StatusAktif" NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: TechnicianSchedule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TechnicianSchedule" (
    id integer NOT NULL,
    "technicianId" integer NOT NULL,
    date timestamp(3) without time zone NOT NULL,
    note text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: TechnicianSchedule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."TechnicianSchedule_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: TechnicianSchedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."TechnicianSchedule_id_seq" OWNED BY public."TechnicianSchedule".id;


--
-- Name: Technician_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Technician_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Technician_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Technician_id_seq" OWNED BY public."Technician".id;


--
-- Name: User; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."User" (
    id integer NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    password text NOT NULL,
    role public."Role" DEFAULT 'STAFF'::public."Role" NOT NULL,
    "technicianId" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: User_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."User_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: User_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."User_id_seq" OWNED BY public."User".id;


--
-- Name: Vehicle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Vehicle" (
    id integer NOT NULL,
    "customerId" integer NOT NULL,
    "vehicleModelId" integer NOT NULL,
    "plateNumber" text NOT NULL,
    vin text,
    "engineNumber" text,
    color text,
    "purchaseYear" integer,
    note text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: VehicleModel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."VehicleModel" (
    id integer NOT NULL,
    brand text NOT NULL,
    model text NOT NULL,
    year integer NOT NULL,
    type text NOT NULL,
    wheels integer DEFAULT 4 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: VehicleModel_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."VehicleModel_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: VehicleModel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."VehicleModel_id_seq" OWNED BY public."VehicleModel".id;


--
-- Name: Vehicle_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Vehicle_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Vehicle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Vehicle_id_seq" OWNED BY public."Vehicle".id;


--
-- Name: Category id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Category" ALTER COLUMN id SET DEFAULT nextval('public."Category_id_seq"'::regclass);


--
-- Name: Customer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Customer" ALTER COLUMN id SET DEFAULT nextval('public."Customer_id_seq"'::regclass);


--
-- Name: Discount id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Discount" ALTER COLUMN id SET DEFAULT nextval('public."Discount_id_seq"'::regclass);


--
-- Name: SalesItem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SalesItem" ALTER COLUMN id SET DEFAULT nextval('public."SalesItem_id_seq"'::regclass);


--
-- Name: SalesTransaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SalesTransaction" ALTER COLUMN id SET DEFAULT nextval('public."SalesTransaction_id_seq"'::regclass);


--
-- Name: ServiceDetail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceDetail" ALTER COLUMN id SET DEFAULT nextval('public."ServiceDetail_id_seq"'::regclass);


--
-- Name: ServiceLog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceLog" ALTER COLUMN id SET DEFAULT nextval('public."ServiceLog_id_seq"'::regclass);


--
-- Name: ServiceSparepart id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceSparepart" ALTER COLUMN id SET DEFAULT nextval('public."ServiceSparepart_id_seq"'::regclass);


--
-- Name: ServiceTransaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceTransaction" ALTER COLUMN id SET DEFAULT nextval('public."ServiceTransaction_id_seq"'::regclass);


--
-- Name: ServiceType id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceType" ALTER COLUMN id SET DEFAULT nextval('public."ServiceType_id_seq"'::regclass);


--
-- Name: Sparepart id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Sparepart" ALTER COLUMN id SET DEFAULT nextval('public."Sparepart_id_seq"'::regclass);


--
-- Name: StockHistory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."StockHistory" ALTER COLUMN id SET DEFAULT nextval('public."StockHistory_id_seq"'::regclass);


--
-- Name: Technician id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Technician" ALTER COLUMN id SET DEFAULT nextval('public."Technician_id_seq"'::regclass);


--
-- Name: TechnicianSchedule id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TechnicianSchedule" ALTER COLUMN id SET DEFAULT nextval('public."TechnicianSchedule_id_seq"'::regclass);


--
-- Name: User id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User" ALTER COLUMN id SET DEFAULT nextval('public."User_id_seq"'::regclass);


--
-- Name: Vehicle id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Vehicle" ALTER COLUMN id SET DEFAULT nextval('public."Vehicle_id_seq"'::regclass);


--
-- Name: VehicleModel id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."VehicleModel" ALTER COLUMN id SET DEFAULT nextval('public."VehicleModel_id_seq"'::regclass);


--
-- Data for Name: Category; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Category" VALUES (1, 'Oli', '2026-10-03 07:34:08.895', '2026-10-03 07:34:08.895');
INSERT INTO public."Category" VALUES (2, 'Ban', '2026-10-03 07:34:08.895', '2026-10-03 07:34:08.895');


--
-- Data for Name: Customer; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: Discount; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: SalesItem; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: SalesTransaction; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ServiceDetail; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ServiceLog; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ServiceSparepart; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ServiceTransaction; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ServiceType; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."ServiceType" VALUES (1, 'Ganti Oli', 'Ganti oli mesin', 50000.00, '2026-10-03 07:34:08.897');
INSERT INTO public."ServiceType" VALUES (2, 'Servis Rutin', 'Pengecekan & penyetelan rutin', 100000.00, '2026-10-03 07:34:08.897');
INSERT INTO public."ServiceType" VALUES (3, 'Tune Up', 'Penyetelan performa mesin', 150000.00, '2026-10-03 07:34:08.897');


--
-- Data for Name: Settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Settings" VALUES (1, 'Self Automotive', 'Jl. Raya Bengkel No. 1', '021-1234567', NULL, NULL, NULL, NULL, 10.00, 10.00, '2026-10-03 07:34:08.887', 'BROWSER', NULL);


--
-- Data for Name: Sparepart; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Sparepart" VALUES (1, 'OLI-001', 'Oli Mesin 4T 1L', 1, 35000.00, 55000.00, 50, 10, '2026-10-03 07:34:08.896', '2026-10-03 07:34:08.896');
INSERT INTO public."Sparepart" VALUES (2, 'BAN-001', 'Ban Motor Ring 14', 2, 180000.00, 250000.00, 8, 5, '2026-10-03 07:34:08.896', '2026-10-03 07:34:08.896');


--
-- Data for Name: StockHistory; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: Technician; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."Technician" VALUES (1, 'Budi Santoso', 'Mesin, Kelistrikan', 'AKTIF', '2026-10-03 07:34:08.889', '2026-10-03 07:34:08.889');


--
-- Data for Name: TechnicianSchedule; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."User" VALUES (1, 'admin', 'admin@selfautomotive.test', '$2a$10$T3lCtzaarEr/ZPCTN5hIwO.b11zfsl5w7yCVwBiOrUcrYm81dQ/26', 'ADMIN', NULL, '2026-10-03 07:34:08.891', '2026-10-03 07:34:08.891');
INSERT INTO public."User" VALUES (2, 'staff', 'staff@selfautomotive.test', '$2a$10$CzpnO9OxKeIY6pEHm0Zb.uZEA.wnD2wt6l0U8wpGMbDYsUNEgHq/e', 'STAFF', NULL, '2026-10-03 07:34:08.891', '2026-10-03 07:34:08.891');
INSERT INTO public."User" VALUES (3, 'teknisi1', 'teknisi1@selfautomotive.test', '$2a$10$FmxavKZxcENl15H/NRm3U.bsqDHCshxChewMaAtZ7X4.Q.lFXcJLW', 'TEKNISI', 1, '2026-10-03 07:34:08.891', '2026-10-03 07:34:08.891');


--
-- Data for Name: Vehicle; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: VehicleModel; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."VehicleModel" VALUES (1, 'Toyota', 'Avanza', 2020, 'MPV', 4, '2026-10-03 07:34:08.893');
INSERT INTO public."VehicleModel" VALUES (2, 'Honda', 'Beat', 2021, 'Motor Matic', 2, '2026-10-03 07:34:08.893');


--
-- Name: Category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Category_id_seq"', 2, true);


--
-- Name: Customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Customer_id_seq"', 1, false);


--
-- Name: Discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Discount_id_seq"', 1, false);


--
-- Name: SalesItem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."SalesItem_id_seq"', 1, false);


--
-- Name: SalesTransaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."SalesTransaction_id_seq"', 1, false);


--
-- Name: ServiceDetail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."ServiceDetail_id_seq"', 1, false);


--
-- Name: ServiceLog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."ServiceLog_id_seq"', 1, false);


--
-- Name: ServiceSparepart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."ServiceSparepart_id_seq"', 1, false);


--
-- Name: ServiceTransaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."ServiceTransaction_id_seq"', 1, false);


--
-- Name: ServiceType_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."ServiceType_id_seq"', 3, true);


--
-- Name: Sparepart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Sparepart_id_seq"', 2, true);


--
-- Name: StockHistory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."StockHistory_id_seq"', 1, false);


--
-- Name: TechnicianSchedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."TechnicianSchedule_id_seq"', 1, false);


--
-- Name: Technician_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Technician_id_seq"', 1, true);


--
-- Name: User_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."User_id_seq"', 3, true);


--
-- Name: VehicleModel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."VehicleModel_id_seq"', 2, true);


--
-- Name: Vehicle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Vehicle_id_seq"', 1, false);


--
-- Name: Category Category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Category"
    ADD CONSTRAINT "Category_pkey" PRIMARY KEY (id);


--
-- Name: Customer Customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_pkey" PRIMARY KEY (id);


--
-- Name: Discount Discount_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT "Discount_pkey" PRIMARY KEY (id);


--
-- Name: SalesItem SalesItem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SalesItem"
    ADD CONSTRAINT "SalesItem_pkey" PRIMARY KEY (id);


--
-- Name: SalesTransaction SalesTransaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SalesTransaction"
    ADD CONSTRAINT "SalesTransaction_pkey" PRIMARY KEY (id);


--
-- Name: ServiceDetail ServiceDetail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceDetail"
    ADD CONSTRAINT "ServiceDetail_pkey" PRIMARY KEY (id);


--
-- Name: ServiceLog ServiceLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceLog"
    ADD CONSTRAINT "ServiceLog_pkey" PRIMARY KEY (id);


--
-- Name: ServiceSparepart ServiceSparepart_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceSparepart"
    ADD CONSTRAINT "ServiceSparepart_pkey" PRIMARY KEY (id);


--
-- Name: ServiceTransaction ServiceTransaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceTransaction"
    ADD CONSTRAINT "ServiceTransaction_pkey" PRIMARY KEY (id);


--
-- Name: ServiceType ServiceType_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceType"
    ADD CONSTRAINT "ServiceType_pkey" PRIMARY KEY (id);


--
-- Name: Settings Settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Settings"
    ADD CONSTRAINT "Settings_pkey" PRIMARY KEY (id);


--
-- Name: Sparepart Sparepart_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Sparepart"
    ADD CONSTRAINT "Sparepart_pkey" PRIMARY KEY (id);


--
-- Name: StockHistory StockHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."StockHistory"
    ADD CONSTRAINT "StockHistory_pkey" PRIMARY KEY (id);


--
-- Name: TechnicianSchedule TechnicianSchedule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TechnicianSchedule"
    ADD CONSTRAINT "TechnicianSchedule_pkey" PRIMARY KEY (id);


--
-- Name: Technician Technician_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Technician"
    ADD CONSTRAINT "Technician_pkey" PRIMARY KEY (id);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: VehicleModel VehicleModel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."VehicleModel"
    ADD CONSTRAINT "VehicleModel_pkey" PRIMARY KEY (id);


--
-- Name: Vehicle Vehicle_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Vehicle"
    ADD CONSTRAINT "Vehicle_pkey" PRIMARY KEY (id);


--
-- Name: Category_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Category_name_idx" ON public."Category" USING btree (name);


--
-- Name: Category_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Category_name_key" ON public."Category" USING btree (name);


--
-- Name: Customer_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Customer_name_idx" ON public."Customer" USING btree (name);


--
-- Name: Customer_phone_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Customer_phone_idx" ON public."Customer" USING btree (phone);


--
-- Name: Discount_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Discount_code_idx" ON public."Discount" USING btree (code);


--
-- Name: Discount_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Discount_code_key" ON public."Discount" USING btree (code);


--
-- Name: Discount_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Discount_status_idx" ON public."Discount" USING btree (status);


--
-- Name: SalesItem_salesId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "SalesItem_salesId_idx" ON public."SalesItem" USING btree ("salesId");


--
-- Name: SalesItem_sparepartId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "SalesItem_sparepartId_idx" ON public."SalesItem" USING btree ("sparepartId");


--
-- Name: SalesTransaction_customerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "SalesTransaction_customerId_idx" ON public."SalesTransaction" USING btree ("customerId");


--
-- Name: SalesTransaction_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "SalesTransaction_date_idx" ON public."SalesTransaction" USING btree (date);


--
-- Name: SalesTransaction_invoiceNo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "SalesTransaction_invoiceNo_key" ON public."SalesTransaction" USING btree ("invoiceNo");


--
-- Name: ServiceDetail_serviceId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceDetail_serviceId_idx" ON public."ServiceDetail" USING btree ("serviceId");


--
-- Name: ServiceLog_serviceId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceLog_serviceId_idx" ON public."ServiceLog" USING btree ("serviceId");


--
-- Name: ServiceSparepart_serviceId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceSparepart_serviceId_idx" ON public."ServiceSparepart" USING btree ("serviceId");


--
-- Name: ServiceSparepart_sparepartId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceSparepart_sparepartId_idx" ON public."ServiceSparepart" USING btree ("sparepartId");


--
-- Name: ServiceTransaction_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceTransaction_date_idx" ON public."ServiceTransaction" USING btree (date);


--
-- Name: ServiceTransaction_invoiceNo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ServiceTransaction_invoiceNo_key" ON public."ServiceTransaction" USING btree ("invoiceNo");


--
-- Name: ServiceTransaction_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceTransaction_status_idx" ON public."ServiceTransaction" USING btree (status);


--
-- Name: ServiceTransaction_technicianId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceTransaction_technicianId_idx" ON public."ServiceTransaction" USING btree ("technicianId");


--
-- Name: ServiceTransaction_vehicleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceTransaction_vehicleId_idx" ON public."ServiceTransaction" USING btree ("vehicleId");


--
-- Name: ServiceType_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ServiceType_name_idx" ON public."ServiceType" USING btree (name);


--
-- Name: Sparepart_categoryId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Sparepart_categoryId_idx" ON public."Sparepart" USING btree ("categoryId");


--
-- Name: Sparepart_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Sparepart_code_idx" ON public."Sparepart" USING btree (code);


--
-- Name: Sparepart_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Sparepart_code_key" ON public."Sparepart" USING btree (code);


--
-- Name: StockHistory_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "StockHistory_createdAt_idx" ON public."StockHistory" USING btree ("createdAt");


--
-- Name: StockHistory_sparepartId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "StockHistory_sparepartId_idx" ON public."StockHistory" USING btree ("sparepartId");


--
-- Name: TechnicianSchedule_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "TechnicianSchedule_date_idx" ON public."TechnicianSchedule" USING btree (date);


--
-- Name: TechnicianSchedule_technicianId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "TechnicianSchedule_technicianId_idx" ON public."TechnicianSchedule" USING btree ("technicianId");


--
-- Name: Technician_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Technician_status_idx" ON public."Technician" USING btree (status);


--
-- Name: User_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_email_key" ON public."User" USING btree (email);


--
-- Name: User_role_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "User_role_idx" ON public."User" USING btree (role);


--
-- Name: User_technicianId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_technicianId_key" ON public."User" USING btree ("technicianId");


--
-- Name: User_username_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_username_key" ON public."User" USING btree (username);


--
-- Name: VehicleModel_brand_model_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "VehicleModel_brand_model_idx" ON public."VehicleModel" USING btree (brand, model);


--
-- Name: Vehicle_customerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Vehicle_customerId_idx" ON public."Vehicle" USING btree ("customerId");


--
-- Name: Vehicle_plateNumber_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Vehicle_plateNumber_idx" ON public."Vehicle" USING btree ("plateNumber");


--
-- Name: Vehicle_plateNumber_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Vehicle_plateNumber_key" ON public."Vehicle" USING btree ("plateNumber");


--
-- Name: SalesItem SalesItem_salesId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SalesItem"
    ADD CONSTRAINT "SalesItem_salesId_fkey" FOREIGN KEY ("salesId") REFERENCES public."SalesTransaction"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SalesItem SalesItem_sparepartId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SalesItem"
    ADD CONSTRAINT "SalesItem_sparepartId_fkey" FOREIGN KEY ("sparepartId") REFERENCES public."Sparepart"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: SalesTransaction SalesTransaction_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SalesTransaction"
    ADD CONSTRAINT "SalesTransaction_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public."Customer"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: SalesTransaction SalesTransaction_discountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SalesTransaction"
    ADD CONSTRAINT "SalesTransaction_discountId_fkey" FOREIGN KEY ("discountId") REFERENCES public."Discount"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ServiceDetail ServiceDetail_serviceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceDetail"
    ADD CONSTRAINT "ServiceDetail_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES public."ServiceTransaction"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ServiceLog ServiceLog_serviceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceLog"
    ADD CONSTRAINT "ServiceLog_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES public."ServiceTransaction"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ServiceSparepart ServiceSparepart_serviceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceSparepart"
    ADD CONSTRAINT "ServiceSparepart_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES public."ServiceTransaction"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ServiceSparepart ServiceSparepart_sparepartId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceSparepart"
    ADD CONSTRAINT "ServiceSparepart_sparepartId_fkey" FOREIGN KEY ("sparepartId") REFERENCES public."Sparepart"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ServiceTransaction ServiceTransaction_discountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceTransaction"
    ADD CONSTRAINT "ServiceTransaction_discountId_fkey" FOREIGN KEY ("discountId") REFERENCES public."Discount"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ServiceTransaction ServiceTransaction_technicianId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceTransaction"
    ADD CONSTRAINT "ServiceTransaction_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES public."Technician"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ServiceTransaction ServiceTransaction_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ServiceTransaction"
    ADD CONSTRAINT "ServiceTransaction_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public."Vehicle"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Sparepart Sparepart_categoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Sparepart"
    ADD CONSTRAINT "Sparepart_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES public."Category"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: StockHistory StockHistory_sparepartId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."StockHistory"
    ADD CONSTRAINT "StockHistory_sparepartId_fkey" FOREIGN KEY ("sparepartId") REFERENCES public."Sparepart"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TechnicianSchedule TechnicianSchedule_technicianId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TechnicianSchedule"
    ADD CONSTRAINT "TechnicianSchedule_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES public."Technician"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: User User_technicianId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES public."Technician"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Vehicle Vehicle_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Vehicle"
    ADD CONSTRAINT "Vehicle_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public."Customer"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Vehicle Vehicle_vehicleModelId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Vehicle"
    ADD CONSTRAINT "Vehicle_vehicleModelId_fkey" FOREIGN KEY ("vehicleModelId") REFERENCES public."VehicleModel"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--


