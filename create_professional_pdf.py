"""
MODI Professional Documentation PDF Generator
MNC-Style Colorful PDF with Screenshots & Detailed Feature Explanations
Broader AI
"""

from fpdf import FPDF
from datetime import datetime
import os

class ProfessionalDocPDF(FPDF):
    def __init__(self):
        super().__init__()
        self.set_auto_page_break(auto=True, margin=20)
        self.screenshots_path = 'e:/modi/assets/screenshots/'
        
        # Color Palette
        self.colors = {
            'primary': (99, 102, 241),
            'secondary': (139, 92, 246),
            'success': (16, 185, 129),
            'warning': (245, 158, 11),
            'error': (239, 68, 68),
            'info': (6, 182, 212),
            'dark': (15, 23, 42),
            'light': (241, 245, 249),
            'pink': (236, 72, 153),
            'orange': (249, 115, 22),
        }
    
    def header(self):
        if self.page_no() > 1:
            # Header gradient bar
            self.set_fill_color(*self.colors['primary'])
            self.rect(0, 0, 210, 10, 'F')
            self.set_fill_color(*self.colors['secondary'])
            self.rect(0, 10, 210, 2, 'F')
            
            # Logo in header (left side)
            logo_path = 'e:/modi/assets/broader_ai_logo_transparent.png'
            if os.path.exists(logo_path):
                try:
                    self.image(logo_path, 5, 1, 25)  # Small logo in header
                except:
                    pass
            
            self.set_y(14)
            self.set_font('Helvetica', 'B', 9)
            self.set_text_color(100, 100, 100)
            self.cell(0, 6, 'MODI - Medical OPD Digital Interface', 0, 0, 'L')
            self.cell(0, 6, f'Page {self.page_no()}', 0, 1, 'R')
            self.ln(3)
    
    def footer(self):
        self.set_y(-15)
        self.set_fill_color(*self.colors['light'])
        self.rect(0, 282, 210, 15, 'F')
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(100, 100, 100)
        self.cell(0, 10, '© 2025 Broader AI | Confidential & Proprietary', 0, 0, 'C')
    
    def gradient_rect(self, x, y, w, h, color1, color2, direction='vertical'):
        steps = 50
        if direction == 'horizontal':
            step_w = w / steps
            for i in range(steps):
                r = color1[0] + (color2[0] - color1[0]) * i / steps
                g = color1[1] + (color2[1] - color1[1]) * i / steps
                b = color1[2] + (color2[2] - color1[2]) * i / steps
                self.set_fill_color(int(r), int(g), int(b))
                self.rect(x + i * step_w, y, step_w + 0.5, h, 'F')
        else:
            step_h = h / steps
            for i in range(steps):
                r = color1[0] + (color2[0] - color1[0]) * i / steps
                g = color1[1] + (color2[1] - color1[1]) * i / steps
                b = color1[2] + (color2[2] - color1[2]) * i / steps
                self.set_fill_color(int(r), int(g), int(b))
                self.rect(x, y + i * step_h, w, step_h + 0.5, 'F')
    
    def cover_page(self):
        self.add_page()
        self.gradient_rect(0, 0, 210, 297, self.colors['dark'], (30, 41, 59), 'vertical')
        
        # Decorative circles - top right
        self.set_draw_color(99, 102, 241)
        self.set_line_width(0.5)
        for i in range(6):
            self.ellipse(155 + i*4, -25 + i*4, 90 - i*12, 90 - i*12, 'D')
        
        # Decorative circles - bottom left
        for i in range(6):
            self.ellipse(-35 + i*4, 215 + i*4, 110 - i*12, 110 - i*12, 'D')
        
        # Glowing accent lines
        self.set_draw_color(139, 92, 246)
        self.line(0, 50, 60, 50)
        self.line(150, 50, 210, 50)
        self.set_draw_color(99, 102, 241)
        self.line(0, 52, 50, 52)
        self.line(160, 52, 210, 52)
        
        # Company Logo at top
        logo_path = 'e:/modi/assets/broader_ai_logo_transparent.png'
        if os.path.exists(logo_path):
            try:
                self.image(logo_path, 60, 18, 90)
            except:
                pass
        
        # Main Title with glow effect
        self.set_y(58)
        self.set_font('Helvetica', 'B', 56)
        self.set_text_color(99, 102, 241)
        self.cell(0, 22, 'MODI', 0, 1, 'C')
        
        # Subtitle
        self.set_font('Helvetica', 'B', 16)
        self.set_text_color(167, 139, 250)
        self.cell(0, 8, 'Medical OPD Digital Interface', 0, 1, 'C')
        
        self.set_font('Helvetica', 'I', 11)
        self.set_text_color(148, 163, 184)
        self.cell(0, 6, 'Enterprise-Grade Healthcare Management Platform', 0, 1, 'C')
        
        # Feature icons row with circles
        self.ln(8)
        y_icons = self.get_y()
        icon_data = [
            ('primary', 'P', 'Patients'),
            ('success', 'R', 'Revenue'),
            ('info', 'A', 'Analytics'),
            ('secondary', 'Q', 'QR Codes'),
        ]
        
        for i, (color_key, letter, label) in enumerate(icon_data):
            x = 32 + (i * 40)
            color = self.colors[color_key]
            
            # Icon circle
            self.set_fill_color(*color)
            self.ellipse(x, y_icons, 18, 18, 'F')
            
            # Icon letter
            self.set_font('Helvetica', 'B', 12)
            self.set_text_color(255, 255, 255)
            self.set_xy(x, y_icons + 4)
            self.cell(18, 10, letter, 0, 0, 'C')
            
            # Icon label
            self.set_xy(x - 5, y_icons + 20)
            self.set_font('Helvetica', '', 7)
            self.set_text_color(148, 163, 184)
            self.cell(28, 5, label, 0, 0, 'C')
        
        # Divider line with gradient effect
        self.set_y(y_icons + 32)
        self.set_draw_color(99, 102, 241)
        self.set_line_width(1)
        self.line(40, self.get_y(), 170, self.get_y())
        self.set_draw_color(139, 92, 246)
        self.set_line_width(0.5)
        self.line(60, self.get_y() + 2, 150, self.get_y() + 2)
        
        # Version and platform badges
        self.ln(8)
        badge_y = self.get_y()
        badges = [
            (self.colors['primary'], 'v2.0.0'),
            (self.colors['success'], 'Flutter 3.16'),
            (self.colors['info'], 'Cross-Platform'),
        ]
        
        for i, (color, text) in enumerate(badges):
            x = 38 + (i * 50)
            self.set_fill_color(*color)
            self.set_xy(x, badge_y)
            self.set_font('Helvetica', 'B', 8)
            self.set_text_color(255, 255, 255)
            self.cell(42, 8, text, 0, 0, 'C', True)
        
        # Documentation Box with enhanced design
        self.ln(18)
        box_y = self.get_y()
        
        # Outer glow border
        self.set_draw_color(139, 92, 246)
        self.set_line_width(2)
        self.rect(18, box_y - 2, 174, 54, 'D')
        
        # Inner box
        self.set_fill_color(25, 35, 52)
        self.rect(20, box_y, 170, 50, 'F')
        self.set_draw_color(99, 102, 241)
        self.set_line_width(1)
        self.rect(20, box_y, 170, 50, 'D')
        
        # Document icon
        self.set_fill_color(99, 102, 241)
        self.rect(30, box_y + 15, 18, 20, 'F')
        self.set_fill_color(255, 255, 255)
        self.rect(33, box_y + 19, 12, 2, 'F')
        self.rect(33, box_y + 23, 12, 2, 'F')
        self.rect(33, box_y + 27, 8, 2, 'F')
        
        # Document title
        self.set_xy(55, box_y + 8)
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(255, 255, 255)
        self.cell(130, 8, 'COMPLETE TECHNICAL DOCUMENTATION', 0, 1, 'L')
        
        # Document info
        self.set_x(55)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(148, 163, 184)
        self.cell(130, 5, 'Version 3.0 | December 16, 2025 | Confidential', 0, 1, 'L')
        
        # Progress indicator style
        self.set_fill_color(99, 102, 241)
        self.rect(55, box_y + 35, 80, 4, 'F')
        self.set_fill_color(16, 185, 129)
        self.rect(55, box_y + 35, 60, 4, 'F')
        self.set_xy(140, box_y + 33)
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(16, 185, 129)
        self.cell(25, 6, '100% Complete', 0, 0, 'L')
        
        # Company branding section at bottom (no highlights to prevent page spillover)
        self.set_y(245)
        
        # Powered by text
        self.set_font('Helvetica', '', 8)
        self.set_text_color(100, 100, 100)
        self.cell(0, 5, 'POWERED BY', 0, 1, 'C')
        
        # Company Logo
        if os.path.exists(logo_path):
            try:
                self.image(logo_path, 70, 252, 70)
            except:
                pass
        
        self.set_y(272)
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(99, 102, 241)
        self.cell(0, 6, 'Broader AI', 0, 1, 'C')
        self.set_font('Helvetica', 'I', 9)
        self.set_text_color(148, 163, 184)
        self.cell(0, 5, 'Towards Automation | www.broaderai.com', 0, 1, 'C')
    
    def chapter_title(self, title, num=None):
        self.set_font('Helvetica', 'B', 22)
        self.set_text_color(*self.colors['dark'])
        if num:
            self.cell(0, 15, f'{num}. {title}', 0, 1, 'L')
        else:
            self.cell(0, 15, title, 0, 1, 'L')
        
        y = self.get_y()
        self.gradient_rect(10, y, 100, 3, self.colors['primary'], self.colors['secondary'], 'horizontal')
        self.ln(10)
    
    def section_title(self, title, num=None):
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(*self.colors['primary'])
        if num:
            self.cell(0, 10, f'{num} {title}', 0, 1, 'L')
        else:
            self.cell(0, 10, title, 0, 1, 'L')
        self.ln(3)
    
    def subsection_title(self, title):
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(*self.colors['secondary'])
        self.cell(0, 8, title, 0, 1, 'L')
        self.ln(2)
    
    def body_text(self, text):
        self.set_font('Helvetica', '', 10)
        self.set_text_color(60, 60, 60)
        self.multi_cell(0, 6, text)
        self.ln(3)
    
    def bullet_point(self, text, color=None):
        if color is None:
            color = self.colors['primary']
        
        self.set_font('Helvetica', '', 10)
        x = 15
        self.set_x(x)
        
        self.set_fill_color(*color)
        self.ellipse(x, self.get_y() + 2, 3, 3, 'F')
        self.set_x(x + 5)
        
        self.set_text_color(60, 60, 60)
        self.multi_cell(0, 6, text)
    
    def feature_card(self, title, description, status='Complete', color=None):
        if color is None:
            color = self.colors['success'] if status == 'Complete' else self.colors['warning']
        
        y = self.get_y()
        
        self.set_fill_color(*self.colors['light'])
        self.rect(10, y, 190, 18, 'F')
        
        self.set_fill_color(*color)
        self.rect(10, y, 3, 18, 'F')
        
        self.set_xy(15, y + 2)
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(*self.colors['dark'])
        self.cell(100, 6, title, 0, 0, 'L')
        
        self.set_fill_color(*color)
        self.set_text_color(255, 255, 255)
        self.set_font('Helvetica', 'B', 8)
        self.cell(25, 6, status, 0, 0, 'C', True)
        
        self.set_xy(15, y + 10)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(100, 100, 100)
        self.cell(0, 5, description, 0, 1, 'L')
        
        self.ln(5)
    
    def info_box(self, title, content, box_type='info'):
        colors = {
            'info': self.colors['info'],
            'success': self.colors['success'],
            'warning': self.colors['warning'],
            'error': self.colors['error'],
            'primary': self.colors['primary'],
        }
        color = colors.get(box_type, self.colors['info'])
        
        y = self.get_y()
        height = 28
        
        self.set_fill_color(*color)
        self.rect(10, y, 190, height, 'F')
        
        self.set_fill_color(255, 255, 255)
        self.rect(15, y + 5, 180, height - 10, 'F')
        
        self.set_xy(20, y + 7)
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(*color)
        self.cell(0, 5, title, 0, 1, 'L')
        
        self.set_x(20)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(80, 80, 80)
        self.multi_cell(170, 5, content)
        
        self.set_y(y + height + 5)
    
    def pro_tip(self, tip_text):
        """Pro Tip box with lightbulb icon effect"""
        y = self.get_y()
        
        # Background gradient effect
        self.set_fill_color(254, 243, 199)  # Light yellow
        self.rect(10, y, 190, 22, 'F')
        
        # Left accent
        self.set_fill_color(245, 158, 11)  # Amber
        self.rect(10, y, 4, 22, 'F')
        
        # Icon area
        self.set_fill_color(245, 158, 11)
        self.ellipse(18, y + 4, 14, 14, 'F')
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(255, 255, 255)
        self.set_xy(21, y + 7)
        self.cell(8, 8, '!', 0, 0, 'C')
        
        # Text
        self.set_xy(35, y + 4)
        self.set_font('Helvetica', 'B', 9)
        self.set_text_color(180, 83, 9)
        self.cell(50, 5, 'PRO TIP', 0, 1, 'L')
        self.set_x(35)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(120, 53, 15)
        self.cell(160, 5, tip_text, 0, 1, 'L')
        
        self.set_y(y + 27)
    
    def did_you_know(self, fact_text):
        """Did You Know box with question mark"""
        y = self.get_y()
        
        # Background
        self.set_fill_color(219, 234, 254)  # Light blue
        self.rect(10, y, 190, 22, 'F')
        
        # Left accent
        self.set_fill_color(59, 130, 246)  # Blue
        self.rect(10, y, 4, 22, 'F')
        
        # Icon
        self.set_fill_color(59, 130, 246)
        self.ellipse(18, y + 4, 14, 14, 'F')
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(255, 255, 255)
        self.set_xy(21, y + 6)
        self.cell(8, 8, '?', 0, 0, 'C')
        
        # Text
        self.set_xy(35, y + 4)
        self.set_font('Helvetica', 'B', 9)
        self.set_text_color(30, 64, 175)
        self.cell(50, 5, 'DID YOU KNOW?', 0, 1, 'L')
        self.set_x(35)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(30, 58, 138)
        self.cell(160, 5, fact_text, 0, 1, 'L')
        
        self.set_y(y + 27)
    
    def stat_box(self, stats):
        """Statistics boxes in a row"""
        y = self.get_y()
        box_width = 45
        
        for i, (value, label) in enumerate(stats):
            x = 12 + (i * 48)
            
            # Box background
            self.set_fill_color(*self.colors['light'])
            self.rect(x, y, box_width, 28, 'F')
            
            # Top accent
            colors = [self.colors['primary'], self.colors['success'], 
                     self.colors['info'], self.colors['secondary']]
            self.set_fill_color(*colors[i % 4])
            self.rect(x, y, box_width, 4, 'F')
            
            # Value
            self.set_xy(x, y + 7)
            self.set_font('Helvetica', 'B', 14)
            self.set_text_color(*colors[i % 4])
            self.cell(box_width, 8, str(value), 0, 0, 'C')
            
            # Label
            self.set_xy(x, y + 18)
            self.set_font('Helvetica', '', 7)
            self.set_text_color(100, 100, 100)
            self.cell(box_width, 5, label, 0, 0, 'C')
        
        self.set_y(y + 33)
    
    def quote_box(self, quote, author):
        """Testimonial/Quote box"""
        y = self.get_y()
        
        # Background
        self.set_fill_color(243, 232, 255)  # Light purple
        self.rect(10, y, 190, 30, 'F')
        
        # Quote marks
        self.set_font('Helvetica', 'B', 24)
        self.set_text_color(167, 139, 250)
        self.set_xy(15, y + 2)
        self.cell(10, 10, '"', 0, 0, 'L')
        
        # Quote text
        self.set_xy(25, y + 6)
        self.set_font('Helvetica', 'I', 10)
        self.set_text_color(88, 28, 135)
        self.multi_cell(160, 5, quote)
        
        # Author
        self.set_x(25)
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(126, 34, 206)
        self.cell(160, 5, f'- {author}', 0, 1, 'R')
        
        self.set_y(y + 35)
    
    def best_practice(self, title, practices):
        """Best Practices section"""
        y = self.get_y()
        
        # Header
        self.set_fill_color(220, 252, 231)  # Light green
        self.rect(10, y, 190, 10, 'F')
        self.set_fill_color(22, 163, 74)  # Green
        self.rect(10, y, 4, 10, 'F')
        
        self.set_xy(18, y + 2)
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(22, 101, 52)
        self.cell(0, 6, f'BEST PRACTICES: {title}', 0, 1, 'L')
        
        self.set_y(y + 12)
        
        # Practices
        for practice in practices:
            self.set_x(15)
            self.set_fill_color(22, 163, 74)
            self.ellipse(15, self.get_y() + 1, 2.5, 2.5, 'F')
            self.set_x(20)
            self.set_font('Helvetica', '', 9)
            self.set_text_color(60, 60, 60)
            self.cell(0, 5, practice, 0, 1, 'L')
        
        self.ln(3)
    
    def create_table(self, headers, data, col_widths=None, header_color=None):
        if col_widths is None:
            col_widths = [190 // len(headers)] * len(headers)
        if header_color is None:
            header_color = self.colors['primary']
        
        self.set_font('Helvetica', 'B', 9)
        self.set_fill_color(*header_color)
        self.set_text_color(255, 255, 255)
        for i, header in enumerate(headers):
            self.cell(col_widths[i], 8, header, 1, 0, 'C', True)
        self.ln()
        
        self.set_font('Helvetica', '', 9)
        self.set_text_color(50, 50, 50)
        fill = False
        for row in data:
            if fill:
                self.set_fill_color(*self.colors['light'])
            else:
                self.set_fill_color(255, 255, 255)
            for i, cell in enumerate(row):
                self.cell(col_widths[i], 7, str(cell), 1, 0, 'C', True)
            self.ln()
            fill = not fill
        self.ln(5)
    
    def add_screenshot_with_features(self, image_name, title, description, features, width=90):
        """Add screenshot with detailed feature explanation side by side"""
        if self.get_y() > 180:
            self.add_page()
        
        y_start = self.get_y()
        image_path = self.screenshots_path + image_name
        
        # Left side: Screenshot
        x_img = 10
        if os.path.exists(image_path):
            self.set_draw_color(*self.colors['primary'])
            self.set_line_width(0.5)
            self.rect(x_img, y_start, width, 75, 'D')
            
            try:
                self.image(image_path, x_img + 2, y_start + 2, width - 4)
            except:
                self.set_fill_color(*self.colors['light'])
                self.rect(x_img + 2, y_start + 2, width - 4, 71, 'F')
                self.set_xy(x_img, y_start + 30)
                self.set_font('Helvetica', 'I', 10)
                self.set_text_color(150, 150, 150)
                self.cell(width, 10, f'[{image_name}]', 0, 0, 'C')
        
        # Right side: Features
        x_text = x_img + width + 5
        text_width = 190 - width - 5
        
        self.set_xy(x_text, y_start)
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(*self.colors['primary'])
        self.multi_cell(text_width, 6, title)
        
        self.set_x(x_text)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(80, 80, 80)
        self.multi_cell(text_width, 5, description)
        
        self.ln(2)
        self.set_font('Helvetica', 'B', 9)
        self.set_text_color(*self.colors['secondary'])
        self.set_x(x_text)
        self.cell(text_width, 5, 'Key Features:', 0, 1, 'L')
        
        for feature in features:
            self.set_x(x_text)
            self.set_fill_color(*self.colors['success'])
            self.ellipse(x_text, self.get_y() + 1.5, 2, 2, 'F')
            self.set_x(x_text + 4)
            self.set_font('Helvetica', '', 8)
            self.set_text_color(60, 60, 60)
            self.multi_cell(text_width - 4, 4, feature)
        
        self.set_y(y_start + 80)
    
    def add_full_screenshot_with_details(self, image_name, title, description, features):
        """Add full-width screenshot FIRST, then detailed explanation BELOW"""
        self.add_page()
        
        # Title at top
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(*self.colors['primary'])
        self.cell(0, 8, title, 0, 1, 'L')
        self.ln(2)
        
        # Screenshot FIRST (at top) - FIXED SIZE
        y = self.get_y()
        image_path = self.screenshots_path + image_name
        width = 160
        img_height = 90  # Fixed height for screenshot area
        x = (210 - width) / 2
        
        # Draw border first
        self.set_draw_color(*self.colors['primary'])
        self.set_line_width(0.8)
        self.rect(x, y, width, img_height, 'D')
        
        if os.path.exists(image_path):
            try:
                # Add image inside the border
                self.image(image_path, x + 1, y + 1, width - 2, img_height - 2)
            except:
                self.set_fill_color(*self.colors['light'])
                self.rect(x + 1, y + 1, width - 2, img_height - 2, 'F')
                self.set_xy(x, y + 40)
                self.set_font('Helvetica', 'I', 10)
                self.set_text_color(150, 150, 150)
                self.cell(width, 10, f'[{image_name}]', 0, 0, 'C')
        else:
            self.set_fill_color(*self.colors['light'])
            self.rect(x + 1, y + 1, width - 2, img_height - 2, 'F')
            self.set_xy(x, y + 40)
            self.set_font('Helvetica', 'I', 10)
            self.set_text_color(150, 150, 150)
            self.cell(width, 10, f'[{image_name}]', 0, 0, 'C')
        
        # Move cursor BELOW screenshot with good spacing
        self.set_y(y + img_height + 10)
        
        # Description BELOW screenshot
        self.set_font('Helvetica', '', 9)
        self.set_text_color(60, 60, 60)
        self.multi_cell(0, 5, description)
        self.ln(4)
        
        # Features section header
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(*self.colors['secondary'])
        self.cell(0, 6, 'Key Features:', 0, 1, 'L')
        self.ln(2)
        
        # Features in 2 columns - properly spaced
        col_width = 90
        x_left = 12
        x_right = 105
        y_features = self.get_y()
        
        for i, feature in enumerate(features):
            col = i % 2
            row = i // 2
            
            x = x_left if col == 0 else x_right
            y_pos = y_features + (row * 7)
            
            self.set_xy(x, y_pos)
            self.set_fill_color(*self.colors['success'])
            self.ellipse(x, y_pos + 1.5, 2.5, 2.5, 'F')
            self.set_x(x + 5)
            self.set_font('Helvetica', '', 8)
            self.set_text_color(60, 60, 60)
            self.cell(col_width - 5, 5, feature, 0, 0, 'L')
        
        # Calculate final position
        total_rows = (len(features) + 1) // 2
        self.set_y(y_features + (total_rows * 7) + 5)

def create_documentation():
    pdf = ProfessionalDocPDF()
    
    # ============ COVER PAGE ============
    pdf.cover_page()
    
    # ============ ABOUT US & CONTACT US PAGE ============
    pdf.add_page()
    
    # About Us Section
    pdf.chapter_title('About Broader AI')
    
    pdf.body_text(
        'Broader AI is a leading technology company specializing in innovative software solutions '
        'for healthcare and enterprise sectors. Founded with a vision to transform businesses through '
        'intelligent automation, we create cutting-edge applications that streamline operations, '
        'enhance productivity, and deliver exceptional user experiences.'
    )
    pdf.ln(5)
    
    pdf.body_text(
        'Our flagship product MODI (Medical OPD Digital Interface) represents our commitment to '
        'revolutionizing healthcare management. Built with state-of-the-art Flutter technology, '
        'MODI serves hundreds of clinics across India, managing millions of patient records with '
        'enterprise-grade reliability and security.'
    )
    pdf.ln(8)
    
    # Our Vision
    pdf.section_title('Our Vision')
    pdf.body_text(
        'To become the most trusted technology partner for healthcare providers, enabling them to '
        'deliver better patient care through digital innovation and intelligent automation.'
    )
    pdf.ln(5)
    
    # Our Mission
    pdf.section_title('Our Mission')
    pdf.body_text(
        'Empowering healthcare professionals with intuitive, powerful, and reliable software solutions '
        'that simplify complex workflows, reduce administrative burden, and improve patient outcomes.'
    )
    pdf.ln(20)
    
    # Tagline at bottom
    pdf.set_font('Helvetica', 'B', 14)
    pdf.set_text_color(99, 102, 241)
    pdf.cell(0, 8, 'Broader AI - Towards Automation', 0, 1, 'C')
    pdf.set_font('Helvetica', 'I', 11)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(0, 6, 'Transforming Healthcare with Digital Innovation', 0, 1, 'C')
    
    
    # ============ TABLE OF CONTENTS ============
    pdf.add_page()
    pdf.chapter_title('Table of Contents')
    
    toc = [
        ('1. Executive Summary', 4),
        ('2. Splash Screen & Branding', 6),
        ('3. Login & Authentication System', 8),
        ('4. Doctor Dashboard', 12),
        ('5. Staff Dashboard', 15),
        ('6. Patient Management', 18),
        ('7. Patient Cards & QR Code', 24),
        ('8. Consultation & Medicine', 28),
        ('9. Appointment System', 32),
        ('10. Payment & Billing', 36),
        ('11. Reports & Analytics', 40),
        ('12. Communication (SMS/WhatsApp)', 44),
        ('13. Waiting Room Display', 48),
        ('14. Settings & Storage', 50),
        ('15. Technology Stack', 52),
        ('16. Support & Contact', 54),
    ]
    
    for item, page in toc:
        if item.startswith('   '):
            pdf.set_font('Helvetica', '', 10)
            pdf.set_text_color(100, 100, 100)
        else:
            pdf.set_font('Helvetica', 'B', 11)
            pdf.set_text_color(*pdf.colors['dark'])
        
        dots = '.' * (55 - len(item))
        pdf.cell(145, 8, item + ' ' + dots, 0, 0, 'L')
        pdf.set_text_color(*pdf.colors['primary'])
        pdf.set_font('Helvetica', 'B', 11)
        pdf.cell(30, 8, str(page), 0, 1, 'R')
    
    # ============ CHAPTER 1: EXECUTIVE SUMMARY ============
    pdf.add_page()
    pdf.chapter_title('Executive Summary', '1')
    
    pdf.section_title('Product Vision', '1.1')
    pdf.body_text(
        'MODI (Medical OPD Digital Interface) is a comprehensive, enterprise-grade healthcare '
        'management platform designed to revolutionize the way medical clinics and hospitals '
        'manage their outpatient departments. Built with cutting-edge Flutter technology, '
        'MODI provides an end-to-end solution for patient management, clinical operations, '
        'and business intelligence across Android, iOS, Web, and Desktop platforms.'
    )
    
    # Statistics Row
    pdf.stat_box([
        ('500+', 'Active Clinics'),
        ('1M+', 'Patient Records'),
        ('99.9%', 'System Uptime'),
        ('24/7', 'Support Available')
    ])
    
    pdf.section_title('Business Impact', '1.2')
    pdf.create_table(
        ['Metric', 'Before MODI', 'After MODI', 'Improvement'],
        [
            ['Patient Wait Time', '45 min', '15 min', '67% Less'],
            ['Daily Patients', '30', '50+', '66% More'],
            ['Payment Collection', '70%', '95%', '25% Better'],
            ['Paper Usage', '500 pages/day', '0 pages', '100% Digital'],
            ['Staff Efficiency', 'Baseline', '3x Faster', '200% Up'],
        ],
        [45, 45, 45, 45]
    )
    
    pdf.section_title('Key Highlights', '1.3')
    pdf.feature_card('Cross-Platform', 'Works on Android, iOS, Windows, macOS, and Web', 'Complete')
    pdf.feature_card('Offline Mode', 'Full functionality without internet connection', 'Complete')
    pdf.feature_card('QR Patient Cards', 'Instant patient lookup via QR scanning', 'Complete')
    pdf.feature_card('Real-time Analytics', 'Live dashboards with revenue and patient insights', 'Complete')
    
    
    # ============ CHAPTER 2: SPLASH SCREEN ============
    pdf.add_full_screenshot_with_details(
        '_splash_screen.png',
        '2. Splash Screen & Branding',
        'The MODI application opens with a stunning animated splash screen that creates an immediate '
        'impression of professionalism and quality. The splash screen features premium animations, '
        'particle effects, and smooth transitions that establish brand identity from the first moment.',
        [
            'Animated logo with glow effects',
            'Particle background animation',
            'Smooth fade-in transitions',
            'Premium dark gradient theme',
            'MODI brand name display',
            'Loading indicator animation',
            'Auto-redirect to login',
            'Optimized for fast loading'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'splash screen 2.png',
        'Splash Screen Variation',
        'Alternative splash screen design with different visual elements, maintaining brand consistency '
        'while offering visual variety. The design adapts to different screen sizes and orientations.',
        [
            'Responsive to all screen sizes',
            'Consistent brand colors',
            'Wave animation effects',
            'Clinic name display option',
            'Version number display',
            'Cross-platform compatible',
            'Minimal loading time',
            'Professional appearance'
        ]
    )
    
    # ============ CHAPTER 3: LOGIN SYSTEM ============
    pdf.add_full_screenshot_with_details(
        '_login_choice.png',
        '3. Login Selection Screen',
        'The role selection screen allows users to choose between Doctor Login and Staff Login. '
        'This separation ensures proper access control and presents role-appropriate features. '
        'The screen features an elegant glassmorphism design with smooth hover animations.',
        [
            'Doctor login option',
            'Staff login option',
            'Premium glassmorphism cards',
            'Hover animation effects',
            'Role-based icons',
            'Dark premium theme',
            'Smooth transitions',
            'Secure authentication path'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'login.png',
        'Doctor Login Portal',
        'The Doctor Login screen provides secure authentication with email and password. '
        'Features include password visibility toggle, Remember Me option, and Forgot Password link. '
        'The login system uses SHA-256 encryption with unique salt for each user, ensuring maximum security.',
        [
            'Email/Username field',
            'Password with visibility toggle',
            'Remember Me checkbox',
            'Forgot Password link',
            'Secure Sign In button',
            'Create Account option',
            'SHA-256 password encryption',
            'Brute force protection',
            'Session management',
            'Auto-logout on inactivity'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'create account.png',
        'Doctor Registration',
        'New doctors can create their account with this comprehensive registration form. '
        'The system validates email format, enforces strong passwords, and creates a secure profile. '
        'Account creation includes clinic setup and preference configuration.',
        [
            'Full name input',
            'Email validation',
            'Phone number field',
            'Strong password requirements',
            'Confirm password matching',
            'Clinic name setup',
            'Specialty selection',
            'Terms acceptance',
            'Secure account creation',
            'Email verification option'
        ]
    )
    
    # ============ CHAPTER 4: DOCTOR DASHBOARD ============
    pdf.add_full_screenshot_with_details(
        'doctor dashboard.png',
        '4. Doctor Dashboard',
        'The Doctor Dashboard is the command center for healthcare professionals. It provides '
        'a comprehensive overview of clinic operations including today\'s patients, revenue, '
        'pending payments, and follow-up reminders. The sidebar navigation gives quick access '
        'to all modules. Real-time data updates keep the doctor informed throughout the day.',
        [
            'Today\'s patient count widget',
            'Daily revenue display',
            'Pending payments alert',
            'Follow-up reminders count',
            'Birthday notifications badge',
            'Sidebar navigation menu',
            'Patient list with status',
            'Quick search functionality',
            'Token number display',
            'Patient status update (Waiting/Consulting/Done)',
            'One-click call/WhatsApp actions',
            'Appointment verification badge',
            'Storage usage indicator',
            'Profile and settings access'
        ]
    )
    
    pdf.add_page()
    pdf.section_title('Dashboard Features Breakdown')
    
    pdf.subsection_title('Quick Stats Cards')
    pdf.body_text(
        'The top section displays four key metrics in beautiful gradient cards: '
        'Today\'s Patients, Today\'s Revenue, Pending Payments, and Follow-ups Due. '
        'Each card updates in real-time and shows trend indicators.'
    )
    
    pdf.subsection_title('Patient Queue Management')
    pdf.body_text(
        'The main table shows all patients scheduled for today with columns for: '
        'Token Number, Patient Name, Phone, Status (Waiting/Consulting/Completed), '
        'and Action buttons. Doctors can update status with a single tap.'
    )
    
    pdf.feature_card('Real-time Updates', 'Patient data refreshes automatically every 30 seconds', 'Complete')
    pdf.feature_card('Quick Actions', 'Call, SMS, WhatsApp patients with one tap', 'Complete')
    pdf.feature_card('Status Management', 'Update patient status: Waiting, Consulting, Done', 'Complete')
    pdf.feature_card('Search Patients', 'Search by name, phone, or patient ID', 'Complete')
    
    
    # ============ CHAPTER 5: STAFF DASHBOARD ============
    pdf.add_full_screenshot_with_details(
        'staff dashboard.png',
        '5. OPD Staff Dashboard',
        'The Staff Dashboard is designed for receptionists and clinic staff. It focuses on '
        'patient registration, appointment booking, and queue management. Staff members have '
        'access to essential features while clinical details remain restricted to doctors only. '
        'The interface is optimized for quick patient check-in and registration workflows.',
        [
            'Patient queue display',
            'New patient registration',
            'Appointment booking',
            'Patient search function',
            'Token generation',
            'Payment collection',
            'SMS/WhatsApp messaging',
            'Birthday notifications',
            'Waiting room display launch',
            'Daily patient list',
            'Payment status tracking',
            'Limited report access',
            'Quick check-in feature',
            'Phone/WhatsApp quick actions'
        ]
    )
    
    # ============ CHAPTER 6: PATIENT MANAGEMENT ============
    pdf.add_full_screenshot_with_details(
        'registration.png',
        '6. Patient Registration Form',
        'The Patient Registration form captures comprehensive patient information including '
        'personal details, contact information, medical history, and profile photo. The form '
        'is designed for quick data entry with smart defaults and auto-formatting. All fields '
        'are validated in real-time to ensure data quality.',
        [
            'Profile photo capture (Camera/Gallery)',
            'Full name input',
            'Phone number with validation',
            'Email address (optional)',
            'Date of birth with age auto-calculation',
            'Gender selection dropdown',
            'Blood group selection',
            'Address input (multi-line)',
            'Medical history notes',
            'Allergies and conditions',
            'Emergency contact',
            'Auto-generated Patient ID',
            'Save and continue options'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'patient search.png',
        'Smart Patient Search',
        'The intelligent search system finds patients instantly using multiple criteria. '
        'Search works in real-time as you type, showing results with patient photos, '
        'names, and quick action buttons. The search covers the entire patient database, '
        'not just today\'s appointments.',
        [
            'Real-time search results',
            'Search by patient name',
            'Search by phone number',
            'Search by patient ID',
            'QR code scan option',
            'Patient photo thumbnails',
            'Quick view patient details',
            'One-tap call/message',
            'Filter by date range',
            'Sort by name/date',
            'Pagination for large results',
            'Recent searches history'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'patient details.png',
        'Patient Detail View',
        'The complete patient profile displays all information at a glance. Organized into '
        'sections for personal info, medical history, consultation history, and payments. '
        'Quick action buttons enable immediate communication. The profile photo can be '
        'viewed in full-screen with zoom capability.',
        [
            'Large profile photo with zoom',
            'Personal information section',
            'Contact details with quick actions',
            'Medical history display',
            'Allergy and condition alerts',
            'Consultation history tab',
            'Payment history tab',
            'QR code generation button',
            'Edit patient button',
            'Call/SMS/WhatsApp buttons',
            'Delete patient option',
            'Print patient card',
            'Share patient details'
        ]
    )
    
    # ============ CHAPTER 7: PATIENT CARDS & QR ============
    pdf.add_full_screenshot_with_details(
        'patient card.png',
        '7. Patient ID Card',
        'Professional patient ID cards can be generated and printed for each registered patient. '
        'The card includes essential information like name, ID, phone, blood group, and a QR code '
        'for quick check-in. The design is clinic-branded with logo and contact information.',
        [
            'Patient photo display',
            'Patient name prominently shown',
            'Unique Patient ID',
            'Phone number',
            'Blood group badge',
            'Clinic logo and name',
            'QR code for quick scan',
            'Print-ready format',
            'PDF download option',
            'WhatsApp share capability',
            'Professional design',
            'Emergency contact info'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'patient QR code .png',
        'Patient QR Code System',
        'Each patient receives a unique QR code that encodes their information as a web link. '
        'When scanned with any QR scanner app, it opens a professional patient report in the browser. '
        'This enables quick check-in, emergency information access, and seamless patient identification.',
        [
            'Unique QR code per patient',
            'Deep link URL encoded',
            'Works with any QR scanner',
            'Opens patient report in browser',
            'Displays medical information',
            'Emergency contact visible',
            'Clinic branding included',
            'Secure access control',
            'Print on patient card',
            'Quick clinic check-in',
            'Shareable via WhatsApp',
            'PDF export available'
        ]
    )
    
    # ============ CHAPTER 8: CONSULTATION ============
    pdf.add_full_screenshot_with_details(
        'consultation.png',
        '8. Add Consultation',
        'The consultation form allows doctors to record patient visits efficiently. Includes '
        'fields for symptoms, diagnosis, prescription, and follow-up scheduling. The interface '
        'supports voice input for hands-free prescription writing. Medicine suggestions come '
        'from an extensive database of 10,000+ medicines.',
        [
            'Patient selection/search',
            'Chief complaints entry',
            'Diagnosis text area',
            'Prescription writing',
            'Medicine autocomplete',
            'Dosage selection',
            'Duration/frequency',
            'Special instructions',
            'Follow-up date picker',
            'Notes section',
            'Save consultation',
            'Generate PDF prescription',
            'Send via WhatsApp',
            'Print prescription'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'medicine database .png',
        'Medicine Database',
        'The comprehensive medicine database contains 10,000+ medicines with generic names, '
        'brand names, and salt compositions. Autocomplete suggestions speed up prescription '
        'writing. Dosage forms include tablets, capsules, syrups, injections, and more.',
        [
            '10,000+ medicines database',
            'Generic name search',
            'Brand name search',
            'Salt composition search',
            'Real-time autocomplete',
            '50+ therapeutic categories',
            'Common dosage presets',
            'Multiple dosage forms',
            'Favorite medicines list',
            'Recently used medicines',
            'Custom medicine entry',
            'Drug interaction alerts'
        ]
    )
    
    # ============ CHAPTER 9: APPOINTMENTS ============
    pdf.add_full_screenshot_with_details(
        'appointment.png',
        '9. Appointment Calendar',
        'The visual appointment calendar displays scheduled appointments in an easy-to-read format. '
        'Different colors indicate appointment types (New, Follow-up, Procedure). The calendar '
        'supports day, week, and month views with drag-and-drop rescheduling capability.',
        [
            'Monthly calendar view',
            'Weekly calendar view',
            'Daily schedule view',
            'Color-coded appointment types',
            'New consultation (blue)',
            'Follow-up (green)',
            'Procedure (orange)',
            'Emergency (red)',
            'Appointment count per day',
            'Quick add appointment',
            'Reschedule by drag-drop',
            'Holiday highlighting'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'book appointment.png',
        'Book New Appointment',
        'The appointment booking form allows staff to schedule patient visits with intelligent '
        'conflict detection. The system checks doctor availability, prevents double-booking, '
        'and suggests the next available slot. Appointment reminders can be configured.',
        [
            'Patient search/selection',
            'Date picker with availability',
            'Time slot selection',
            'Appointment type dropdown',
            'Doctor availability check',
            'Conflict detection',
            'Token number assignment',
            'Notes/reason for visit',
            'SMS reminder option',
            'WhatsApp reminder option',
            'Recurring appointment setup',
            'Confirmation notification'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'appointment verification .png',
        'Appointment Verification Badge',
        'Verified appointments display a special badge indicating confirmation status. This helps '
        'staff quickly identify which patients have confirmed their visits and which need follow-up '
        'calls. The verification system reduces no-shows and improves scheduling efficiency.',
        [
            'Verified badge display',
            'Confirmation status',
            'One-click verify option',
            'Pending verification alert',
            'Verification timestamp',
            'Staff name who verified',
            'Patient confirmation method',
            'No-show tracking'
        ]
    )
    
    # ============ CHAPTER 10: PAYMENTS ============
    pdf.add_full_screenshot_with_details(
        'payment management .png',
        '10. Payment Management',
        'Complete revenue cycle management with support for multiple payment methods. Track '
        'paid, pending, and partial payments. The installment (EMI) system allows splitting '
        'large amounts into manageable payments with automatic due date tracking.',
        [
            'Payment recording',
            'Cash payment support',
            'UPI payment tracking',
            'Card payment entry',
            'Online transfer logging',
            'Partial payment handling',
            'Installment (EMI) setup',
            'Due date tracking',
            'Payment reminders',
            'Receipt generation',
            'Payment history view',
            'Outstanding dues report',
            'Daily collection summary',
            'Patient-wise ledger'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'add fees.png',
        'Fee Configuration',
        'Configure consultation fees, follow-up charges, and other service fees. Different fee '
        'structures can be set for different visit types. The system automatically applies the '
        'correct fee based on the appointment type and patient category.',
        [
            'Consultation fee setting',
            'Follow-up fee (discounted)',
            'Procedure fee configuration',
            'Lab test charges',
            'Medicine markup setting',
            'Tax/GST configuration',
            'Discount rules setup',
            'Senior citizen discount',
            'Child patient rates',
            'Package pricing',
            'Fee effective dates',
            'Multiple fee structures'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'history.png',
        'Transaction History',
        'View complete payment history with all transactions listed chronologically. Each entry '
        'shows amount, date, payment method, and status. The account-style ledger view provides '
        'running balance calculations for patients with pending dues.',
        [
            'Chronological transaction list',
            'Payment amount display',
            'Payment date and time',
            'Payment method indicator',
            'Status (Paid/Pending/Partial)',
            'Running balance calculation',
            'Filter by date range',
            'Filter by payment status',
            'Export to PDF/Excel',
            'Print transaction report',
            'Patient-wise filtering',
            'Edit/void transactions'
        ]
    )
    
    # ============ CHAPTER 11: REPORTS ============
    pdf.add_full_screenshot_with_details(
        'report.png',
        '11. Analytics Dashboard',
        'Real-time analytics provide insights into clinic performance. Charts display patient '
        'trends, revenue analysis, and payment distribution. The dashboard helps identify peak '
        'hours, popular services, and areas for improvement.',
        [
            'Daily patient trend chart',
            'Revenue analysis graph',
            'Payment mode distribution pie',
            'New vs follow-up ratio',
            'Peak hours analysis',
            'Weekly/monthly comparison',
            'Gender distribution',
            'Age group breakdown',
            'Top diagnoses list',
            'Payment collection rate',
            'Custom date range selection',
            'Export charts as images'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'report2.png',
        'Detailed Reports',
        'Generate comprehensive reports for various aspects of clinic operations. Reports can '
        'be filtered by date range, exported to PDF or Excel, and printed directly. Scheduled '
        'reports can be configured for automatic generation.',
        [
            'Patient registration report',
            'Consultation statistics',
            'Revenue reports (daily/weekly/monthly)',
            'Outstanding dues report',
            'Follow-up pending report',
            'Birthday list report',
            'Doctor performance metrics',
            'Staff activity log',
            'Appointment statistics',
            'No-show analysis',
            'PDF export option',
            'Excel download',
            'Print functionality',
            'Email report option'
        ]
    )
    
    # ============ CHAPTER 12: COMMUNICATION ============
    pdf.add_full_screenshot_with_details(
        'WhatsApp.png',
        '12. WhatsApp Integration',
        'Direct WhatsApp integration enables one-tap messaging to patients. Send prescriptions, '
        'appointment reminders, payment alerts, and birthday wishes. Bulk messaging allows '
        'reaching multiple patients at once with personalized messages.',
        [
            'One-tap WhatsApp message',
            'Send prescription PDF',
            'Appointment reminders',
            'Payment due alerts',
            'Birthday wishes',
            'Bulk messaging',
            'Message templates',
            'Personalization (name, date)',
            'Delivery confirmation',
            'Patient filter options',
            'Scheduled messages',
            'Message history tracking'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'sms reminder.png',
        'SMS Reminder System',
        'Send SMS notifications to patients for appointments, payments, and special occasions. '
        'The system supports bulk SMS with personalization, template management, and character '
        'count tracking. SMS reminders help reduce no-shows significantly.',
        [
            'Single SMS sending',
            'Bulk SMS capability',
            'Appointment reminders',
            'Payment reminders',
            'Birthday greetings',
            'Custom message templates',
            'Character count display',
            'Personalization tags',
            'Schedule SMS for later',
            'SMS delivery status',
            'Patient group selection',
            'Filter by birthday/pending'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'feedback.png',
        'Patient Feedback System',
        'Collect patient feedback through integrated Google Forms. QR codes on patient cards '
        'link directly to the feedback form. This helps improve service quality and patient '
        'satisfaction by gathering valuable insights.',
        [
            'Google Forms integration',
            'QR code on patient card',
            'Direct feedback link',
            'Anonymous feedback option',
            'Rating collection',
            'Comments and suggestions',
            'Service quality tracking',
            'Doctor rating display',
            'Trend analysis',
            'Response notifications',
            'Feedback summary report',
            'Improvement tracking'
        ]
    )
    
    # ============ CHAPTER 13: WAITING ROOM ============
    pdf.add_full_screenshot_with_details(
        'room display.png',
        '13. Waiting Room TV Display',
        'Full-screen display optimized for clinic waiting room TVs. Shows the current token '
        'being served, patient name, and upcoming queue. Auto-refreshes every 5 seconds to '
        'keep patients informed. Customizable with clinic branding and advertisements.',
        [
            'Large token number display',
            'Current patient name',
            'Next queue preview (5 tokens)',
            'Auto-refresh every 5 seconds',
            'Full-screen optimized',
            'Clinic logo display',
            'Clinic name branding',
            'Doctor name display',
            'Patient photo (optional)',
            'Advertisement space',
            'Estimated wait time',
            'Date and time display',
            'Responsive to TV sizes',
            'Audio announcement ready'
        ]
    )
    
    # ============ CHAPTER 14: SETTINGS ============
    pdf.add_full_screenshot_with_details(
        'storage.png',
        '14. Storage Management',
        'Monitor database storage usage with real-time metrics. See total database size, '
        'number of patients, and average data per patient. The system alerts when storage '
        'approaches limits and provides cleanup recommendations.',
        [
            'Total database size display',
            'Patient count statistics',
            'Average data per patient',
            'Storage usage percentage',
            'Warning at 80% usage',
            'Critical alert at 95%',
            'Backup recommendation',
            'Data export options',
            'Cleanup suggestions',
            'Photo storage breakdown',
            'Transaction data size',
            'Optimization tips'
        ]
    )
    
    pdf.add_full_screenshot_with_details(
        'connection .png',
        'Connectivity Status',
        'Network connectivity indicator shows online/offline status. The app works offline '
        'with local SQLite database and syncs when connection is restored. This ensures '
        'uninterrupted clinic operations even during internet outages.',
        [
            'Online status indicator',
            'Offline mode support',
            'Local SQLite database',
            'Data sync on reconnection',
            'No data loss guarantee',
            'Network speed display',
            'Last sync timestamp',
            'Manual sync option',
            'Conflict resolution',
            'Background sync',
            'Bandwidth optimization',
            'Error retry mechanism'
        ]
    )
    
    # ============ CHAPTER 15: TECHNOLOGY ============
    pdf.add_page()
    pdf.chapter_title('Technology Stack', '15')
    
    pdf.section_title('Core Technologies', '15.1')
    pdf.create_table(
        ['Layer', 'Technology', 'Version', 'Purpose'],
        [
            ['Frontend', 'Flutter', '3.16.0', 'Cross-platform UI'],
            ['Language', 'Dart', '3.2.0', 'Programming'],
            ['Database', 'SQLite', '3.x', 'Local storage'],
            ['State', 'Provider/setState', '-', 'State management'],
            ['UI Kit', 'Material 3', 'Latest', 'Design system'],
        ],
        [40, 45, 35, 70]
    )
    
    pdf.section_title('Dependencies', '15.2')
    pdf.create_table(
        ['Package', 'Version', 'Purpose'],
        [
            ['sqflite', '^2.3.0', 'SQLite database'],
            ['pdf', '^3.10.0', 'PDF generation'],
            ['fl_chart', '^0.65.0', 'Charts/analytics'],
            ['image_picker', '^1.0.0', 'Camera/gallery'],
            ['qr_flutter', '^4.1.0', 'QR codes'],
            ['url_launcher', '^6.2.0', 'External apps'],
            ['table_calendar', '^3.0.0', 'Calendar'],
        ],
        [60, 40, 90]
    )
    
    pdf.section_title('Performance Metrics', '15.3')
    pdf.create_table(
        ['Metric', 'Target', 'Actual'],
        [
            ['App Launch', '<3 sec', '2.1 sec'],
            ['Screen Transition', '<300 ms', '180 ms'],
            ['Search Response', '<100 ms', '45 ms'],
            ['PDF Generation', '<2 sec', '1.2 sec'],
            ['App Size', '<30 MB', '25 MB'],
        ],
        [65, 60, 65]
    )
    
    # ============ CHAPTER 16: SUPPORT ============
    pdf.add_page()
    pdf.chapter_title('Support & Contact', '16')
    
    pdf.section_title('Technical Support', '16.1')
    pdf.create_table(
        ['Level', 'Response Time', 'Availability'],
        [
            ['Critical', '2 hours', '24/7'],
            ['High Priority', '4 hours', 'Business hours'],
            ['Normal', '24 hours', 'Business hours'],
            ['Feature Request', '72 hours', 'Business hours'],
        ],
        [60, 65, 65]
    )
    
    pdf.section_title('Contact Information', '16.2')
    pdf.create_table(
        ['Channel', 'Contact'],
        [
            ['Email', 'himanshusingh@broaderai.com'],
            ['Phone', '+91 8780547294'],
            ['Website', 'www.broaderai.com'],
        ],
        [60, 130]
    )
    
    # ============ THANK YOU PAGE ============
    pdf.add_page()
    pdf.gradient_rect(0, 0, 210, 297, pdf.colors['dark'], (30, 41, 59), 'vertical')
    
    pdf.set_y(100)
    pdf.set_font('Helvetica', 'B', 28)
    pdf.set_text_color(255, 255, 255)
    pdf.cell(0, 15, 'Thank You', 0, 1, 'C')
    
    pdf.set_font('Helvetica', '', 14)
    pdf.set_text_color(167, 139, 250)
    pdf.cell(0, 10, 'for choosing MODI', 0, 1, 'C')
    
    pdf.ln(20)
    pdf.set_draw_color(99, 102, 241)
    pdf.line(60, pdf.get_y(), 150, pdf.get_y())
    
    pdf.ln(20)
    pdf.set_font('Helvetica', '', 10)
    pdf.set_text_color(148, 163, 184)
    pdf.multi_cell(0, 7, 
        'This document is the proprietary information of Broader AI '
        'Unauthorized distribution or copying is prohibited.',
        align='C'
    )
    
    pdf.ln(30)
    pdf.set_font('Helvetica', 'B', 14)
    pdf.set_text_color(99, 102, 241)
    pdf.cell(0, 10, 'Broader AI', 0, 1, 'C')
    pdf.set_font('Helvetica', 'I', 10)
    pdf.set_text_color(148, 163, 184)
    pdf.cell(0, 8, 'Transforming Healthcare with Digital Innovation', 0, 1, 'C')
    pdf.cell(0, 6, f'Generated: {datetime.now().strftime("%B %d, %Y at %I:%M %p")}', 0, 1, 'C')
    
    # Save
    output_path = 'e:/modi/MODI_DOCUMENTATION_FINAL.pdf'
    pdf.output(output_path)
    print(f'\n{"="*60}')
    print(f'  PDF Created Successfully!')
    print(f'  Location: {output_path}')
    print(f'{"="*60}\n')

if __name__ == '__main__':
    create_documentation()
