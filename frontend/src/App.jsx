import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';

import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import CustomerList from './pages/customers/CustomerList';
import CustomerForm from './pages/customers/CustomerForm';
import CustomerDetail from './pages/customers/CustomerDetail';
import VehicleList from './pages/vehicles/VehicleList';
import VehicleForm from './pages/vehicles/VehicleForm';
import VehicleDetail from './pages/vehicles/VehicleDetail';
import VehicleMasterList from './pages/vehicles/VehicleMasterList';
import VehicleModelForm from './pages/vehicles/VehicleModelForm';
import SparepartList from './pages/spareparts/SparepartList';
import SparepartForm from './pages/spareparts/SparepartForm';
import CategoryList from './pages/spareparts/CategoryList';
import CategoryForm from './pages/spareparts/CategoryForm';
import StockHistory from './pages/spareparts/StockHistory';
import StockMoveForm from './pages/spareparts/StockMoveForm';
import ServiceList from './pages/services/ServiceList';
import ServiceForm from './pages/services/ServiceForm';
import ServiceDetail from './pages/services/ServiceDetail';
import ServiceTypeList from './pages/service-types/ServiceTypeList';
import ServiceTypeForm from './pages/service-types/ServiceTypeForm';
import SalesList from './pages/sales/SalesList';
import SalesAdd from './pages/sales/SalesAdd';
import SalesDetail from './pages/sales/SalesDetail';
import TechnicianList from './pages/technicians/TechnicianList';
import TechnicianForm from './pages/technicians/TechnicianForm';
import TechnicianDetail from './pages/technicians/TechnicianDetail';
import ScheduleForm from './pages/technicians/ScheduleForm';
import Reports from './pages/reports/Reports';
import UserList from './pages/users/UserList';
import UserForm from './pages/users/UserForm';
import SettingsPage from './pages/admin/SettingsPage';
import DiscountList from './pages/admin/DiscountList';
import DiscountForm from './pages/admin/DiscountForm';

const OPS = ['ADMIN', 'STAFF'];
const ADMIN = ['ADMIN'];
const ALL = ['ADMIN', 'STAFF', 'TEKNISI'];

// Pembungkus singkat: membatasi halaman berdasarkan role
const guard = (roles, element) => <ProtectedRoute roles={roles}>{element}</ProtectedRoute>;

export default function App() {
  const { user } = useAuth();

  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to="/" replace /> : <Login />} />

      <Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
        {/* Dashboard: sama untuk semua role (aksi tambah stok dibatasi di dalam halaman) */}
        <Route index element={<Dashboard />} />

        {/* Pelanggan */}
        <Route path="customers" element={guard(OPS, <CustomerList />)} />
        <Route path="customers/new" element={guard(OPS, <CustomerForm />)} />
        <Route path="customers/:id" element={guard(OPS, <CustomerDetail />)} />
        <Route path="customers/:id/edit" element={guard(OPS, <CustomerForm />)} />

        {/* Sparepart: Data, Kategori, Riwayat Stok */}
        <Route path="spareparts" element={guard(OPS, <SparepartList />)} />
        <Route path="spareparts/new" element={guard(OPS, <SparepartForm />)} />
        <Route path="spareparts/:id/edit" element={guard(OPS, <SparepartForm />)} />
        <Route path="spareparts/categories" element={guard(OPS, <CategoryList />)} />
        <Route path="spareparts/categories/new" element={guard(OPS, <CategoryForm />)} />
        <Route path="spareparts/categories/:id/edit" element={guard(OPS, <CategoryForm />)} />
        <Route path="spareparts/stock-history" element={guard(OPS, <StockHistory />)} />
        <Route path="spareparts/stock-history/in" element={guard(OPS, <StockMoveForm direction="MASUK" />)} />
        <Route path="spareparts/stock-history/out" element={guard(OPS, <StockMoveForm direction="KELUAR" />)} />

        {/* Kendaraan: Data, Master */}
        <Route path="vehicles" element={guard(OPS, <VehicleList />)} />
        <Route path="vehicles/new" element={guard(OPS, <VehicleForm />)} />
        <Route path="vehicles/master" element={guard(OPS, <VehicleMasterList />)} />
        <Route path="vehicles/master/new" element={guard(OPS, <VehicleModelForm />)} />
        <Route path="vehicles/master/:id/edit" element={guard(OPS, <VehicleModelForm />)} />
        <Route path="vehicles/:id" element={guard(OPS, <VehicleDetail />)} />
        <Route path="vehicles/:id/edit" element={guard(OPS, <VehicleForm />)} />

        {/* Layanan: Data Layanan, Jenis Layanan */}
        <Route path="services" element={<ServiceList />} />
        <Route path="services/new" element={guard(ALL, <ServiceForm />)} />
        <Route path="services/:id" element={<ServiceDetail />} />
        <Route path="services/:id/edit" element={guard(OPS, <ServiceForm />)} />
        <Route path="service-types" element={guard(OPS, <ServiceTypeList />)} />
        <Route path="service-types/new" element={guard(OPS, <ServiceTypeForm />)} />
        <Route path="service-types/:id/edit" element={guard(OPS, <ServiceTypeForm />)} />

        {/* Penjualan */}
        <Route path="sales" element={guard(OPS, <SalesList />)} />
        <Route path="sales/new" element={guard(OPS, <SalesAdd />)} />
        <Route path="sales/:id" element={guard(OPS, <SalesDetail />)} />

        {/* Teknisi */}
        <Route path="technicians" element={guard(OPS, <TechnicianList />)} />
        <Route path="technicians/new" element={guard(OPS, <TechnicianForm />)} />
        <Route path="technicians/:id" element={guard(OPS, <TechnicianDetail />)} />
        <Route path="technicians/:id/edit" element={guard(OPS, <TechnicianForm />)} />
        <Route path="technicians/:id/schedules/new" element={guard(OPS, <ScheduleForm />)} />
        <Route path="technicians/:id/schedules/:scheduleId/edit" element={guard(OPS, <ScheduleForm />)} />

        {/* Laporan: /reports/stock | service | sales */}
        <Route path="reports" element={<Navigate to="/reports/stock" replace />} />
        <Route path="reports/:tab" element={guard(OPS, <Reports />)} />

        {/* Users */}
        <Route path="users" element={guard(ADMIN, <UserList />)} />
        <Route path="users/new" element={guard(ADMIN, <UserForm />)} />
        <Route path="users/:id/edit" element={guard(ADMIN, <UserForm />)} />

        {/* Admin: Pengaturan, Diskon */}
        <Route path="admin" element={<Navigate to="/admin/settings" replace />} />
        <Route path="admin/settings" element={guard(ADMIN, <SettingsPage />)} />
        <Route path="admin/discounts" element={guard(ADMIN, <DiscountList />)} />
        <Route path="admin/discounts/new" element={guard(ADMIN, <DiscountForm />)} />
        <Route path="admin/discounts/:id/edit" element={guard(ADMIN, <DiscountForm />)} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
