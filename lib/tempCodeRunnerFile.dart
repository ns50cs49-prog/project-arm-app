Future<void> _showAddDoctorDialog() async {
    _clearForm();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มข้อมูลหมอ'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'ชื่อหมอ',
                hintText: 'เช่น นพ. สมชาย นาคมศักดิ์',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: 'อีเมลหมอ',
                hintText: 'เช่น doctor@example.com',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _loginIdController,
                label: 'รหัสล็อกอินหมอ',
                hintText: 'เช่น doc1001',
              ),
            ],
          ),
        ),