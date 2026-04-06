`timescale 1ns / 1ps

package UiThemePkg;
    localparam logic [11:0] UI_COLOR_TEXT_PRIMARY   = 12'hFFF;
    localparam logic [11:0] UI_COLOR_TEXT_MUTED     = 12'hBBB;
    localparam logic [11:0] UI_COLOR_PANEL_BG       = 12'h233;
    localparam logic [11:0] UI_COLOR_PANEL_BORDER   = 12'h9AC;
    localparam logic [11:0] UI_COLOR_TOOLBAR_BG     = 12'h112;
    localparam logic [11:0] UI_COLOR_TOOLBAR_ACCENT = 12'hFD6;

    localparam int UI_SCREEN_W = 640;
    localparam int UI_SCREEN_H = 480;

    localparam int UI_PROPERTY_PANEL_X = 0;
    localparam int UI_PROPERTY_PANEL_Y = 0;
    localparam int UI_PROPERTY_PANEL_W = 640;
    localparam int UI_PROPERTY_PANEL_H = 64;

    localparam int UI_TOOLBAR_X = 0;
    localparam int UI_TOOLBAR_Y = 64;
    localparam int UI_TOOLBAR_W = 64;
    localparam int UI_TOOLBAR_H = 288;

    localparam int UI_Z_CANVAS   = 0;
    localparam int UI_Z_OVERLAY  = 1;
    localparam int UI_Z_PANEL    = 2;
    localparam int UI_Z_CURSOR   = 3;
endpackage
