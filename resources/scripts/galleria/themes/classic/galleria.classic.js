/**
 * Galleria Classic Theme 2012-08-08
 * http://galleria.io
 *
 * Licensed under the MIT license
 * https://raw.github.com/aino/galleria/master/LICENSE
 *
 */

(function($) {

/*global jQuery, Galleria */

Galleria.addTheme({
    name: 'classic',
    author: 'Galleria',
    css: 'galleria.classic.css',
    defaults: {
        transition: 'slide',
        thumbCrop:  'height',

        // set this to false if you want to show the caption all the time:
        _toggleInfo: true
    },
    init: function(options) {

        Galleria.requires(1.28, 'This version of Classic theme requires Galleria 1.2.8 or later');

        // add some elements
        this.addElement('info-link','info-close');
        this.append({
            'info' : ['info-link','info-close']
        });

        // cache some stuff
        var info = this.$('info-link,info-close,info-text'),
            touch = Galleria.TOUCH,
            click = touch ? 'touchstart' : 'click';

        // show loader & counter with opacity
        this.$('loader,counter').show().css('opacity', 0.4);

        // some stuff for non-touch browsers
        if (! touch ) {
            this.addIdleState( this.get('image-nav-left'), { left:-50 });
            this.addIdleState( this.get('image-nav-right'), { right:-50 });
            this.addIdleState( this.get('counter'), { opacity:0 });
        }

        // toggle info
        //info.show();
        //info.delay(3000).fadeOut('slow');
        self = this;
        //this.$('info-link').fadeIn(1);
        //$('.galleria-info-link').show();
        if ( options._toggleInfo === true ) {
            $('.galleria-info-link').bind( click,function(e) {
                if( ! $(this).hasClass('galleria-active')){
                    $('.galleria-info-link').addClass('galleria-active');
      
                    $('.galleria-stage').stop().animate({"padding-left":"210px"}, 500, function() {
                        $('.galleria-stage').css({"padding-left":"210px"});
                        self.refreshImage();
                    });
                    $('.galleria-info').stop().animate({"left":"15px"}, 500, function() {
                        $('.galleria-info').css({"left":"15px"});
                    });
                } else {
                    $('.galleria-info-link').removeClass('galleria-active');
                    $('.galleria-stage').stop().animate({"padding-left":"0px"}, 500, function() {
                        $('.galleria-stage').css({"padding-left":"0px"});
                        self.refreshImage();
                    });
                    $('.galleria-info').stop().animate({"left":"-200px"}, 500, function() {
                            $('.galleria-info').css({"left":"-200px"});
                        });
                }
            });
            /*
            this.$('info').bind( click, function() {
                //info.toggle(false);
                    $('.galleria-stage').stop().animate({"padding-left":"0px"}, 500, function() {
                        self.refreshImage();
                    }); 
                $('.galleria-info').stop().animate({"left":"-200px"}, 500, function() {
                        $('.galleria-info').css({"left":"-200px"});
                    });
            });
            */
            
        } else {
            info.show();
            this.$('info-link, info-close').hide();
        }
        
        
        // bind some stuff
        this.bind('thumbnail', function(e) {

            if (! touch ) {
                // fade thumbnails
                $(e.thumbTarget).css('opacity', 0.6).parent().hover(function() {
                    $(this).not('.active').children().stop().fadeTo(100, 1);
                }, function() {
                    $(this).not('.active').children().stop().fadeTo(400, 0.6);
                });

                if ( e.index === this.getIndex() ) {
                    $(e.thumbTarget).css('opacity',1);
                }
            } else {
                $(e.thumbTarget).css('opacity', this.getIndex() ? 1 : 0.6);
            }
        });

        this.bind('loadstart', function(e) {
            if (!e.cached) {
                this.$('loader').show().fadeTo(200, 0.4);
            }

            //this.$('info').toggle( this.hasInfo() );
            /*
            if (this.hasInfo()) {
                $('.galleria-info-link').removeClass('galleria-active');
                self.$('info-link').click();
            }
            */
            $(e.thumbTarget).css('opacity',1).parent().siblings().children().css('opacity', 0.6);
        });

        this.bind('loadfinish', function(e) {
            this.$('loader').fadeOut(200);
        });
    }
});

}(jQuery));
