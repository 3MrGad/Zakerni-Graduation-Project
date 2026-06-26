<?php

namespace Database\Seeders;

use App\Models\Admin;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        Admin::firstOrCreate(
            ['username' => 'admin'],
            [
                'password' => Hash::make('admin123'),
                'role'     => 'admin',
            ]
        );
    }
}
