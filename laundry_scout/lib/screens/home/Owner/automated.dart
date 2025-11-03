import 'package:flutter/material.dart';

class AutomatedMessagesScreen extends StatefulWidget {
  const AutomatedMessagesScreen({super.key});

  @override
  State<AutomatedMessagesScreen> createState() => _AutomatedMessagesScreenState();
}

class _AutomatedMessagesScreenState extends State<AutomatedMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A35E3),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Automated Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Automated Message Templates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Welcome message template
                      _buildMessageTemplate(
                        title: 'Welcome Message',
                        description: 'Automatically sent when a customer starts a conversation',
                        icon: Icons.waving_hand,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 15),
                      // Order confirmation template
                      _buildMessageTemplate(
                        title: 'Order Confirmation',
                        description: 'Sent when an order is placed',
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 15),
                      // Order ready template
                      _buildMessageTemplate(
                        title: 'Order Ready',
                        description: 'Notifies customer when their laundry is ready',
                        icon: Icons.check_circle,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 15),
                      // Follow-up template
                      _buildMessageTemplate(
                        title: 'Follow-up Message',
                        description: 'Sent after order completion',
                        icon: Icons.chat_bubble,
                        color: Colors.purple,
                      ),
                      const Spacer(),
                      // Add new template button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to create new template
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Create new template feature coming soon!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A35E3),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create New Template',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTemplate({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey),
            onPressed: () {
              // Edit template functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Edit $title template'),
                  backgroundColor: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}